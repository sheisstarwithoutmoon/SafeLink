import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  Future<String?> _getUserId() async {
    return await _storage.getUserId();
  }

  Map<String, String> _getHeaders([String? userId, String? firebaseToken]) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // Prefer Firebase token over user ID
    if (firebaseToken != null) {
      headers['Authorization'] = 'Bearer $firebaseToken';
    } else if (userId != null) {
      headers['x-user-id'] = userId;
    }
    
    return headers;
  }

  /// Register or login user with Firebase Authentication
  Future<Map<String, dynamic>> registerUser({
    String? phoneNumber,
    String? phone,
    String? name,
    String? fcmToken,
    String? firebaseToken, // New: Firebase ID token
  }) async {
    try {
      print('Sending registration request to: ${ApiConfig.registerUrl}');

      final body = <String, dynamic>{};
      
      // Use Firebase token if available (new method)
      if (firebaseToken != null) {
        print('Using Firebase Authentication');
        body['firebaseToken'] = firebaseToken;
        if (name != null) body['name'] = name;
        if (fcmToken != null) body['fcmToken'] = fcmToken;
      } else {
        // Fallback to old method (backward compatibility)
        print('Using legacy phone registration');
        final phoneNum = phone ?? phoneNumber;
        if (phoneNum == null) throw Exception('Phone number required');
        body['phoneNumber'] = phoneNum;
        if (name != null) body['name'] = name;
        if (fcmToken != null) body['fcmToken'] = fcmToken;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save user ID locally
        final userId = data['user']['_id'] ?? data['user']['id'];
        print('Saving user ID: $userId');
        await _storage.saveUserId(userId);
        
        // Save phone number if available
        final userPhone = data['user']['phoneNumber'];
        if (userPhone != null) {
          await _storage.savePhoneNumber(userPhone);
        }
        
        // Return with isNewUser flag (from backend or default to false)
        return {
          'success': true, 
          'user': data['user'],
          'isNewUser': data['isNewUser'] ?? false,
        };
      } else {
        print('Registration failed: ${data['error'] ?? data['message']}');
        return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Error in registerUser: $e');
      if (e.toString().contains('TimeoutException')) {
        return {'success': false, 'message': 'Server timeout. Please check your internet connection.'};
      } else if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Please check your internet.'};
      }
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse(ApiConfig.profileUrl),
        headers: _getHeaders(userId),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['user'];
      } else {
        throw Exception(data['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      print('Error in getProfile: $e');
      rethrow;
    }
  }

  /// Add emergency contact
  Future<Map<String, dynamic>> addEmergencyContact({
    required String userId,
    String? phoneNumber,
    String? phone,
    String? name,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final phoneNum = phone ?? phoneNumber;
      if (phoneNum == null) throw Exception('Phone number required');

      final response = await http.post(
        Uri.parse(ApiConfig.emergencyContactsUrl),
        headers: _getHeaders(userId),
        body: jsonEncode({
          'phoneNumber': phoneNum,
          'name': name,
          'relationship': relationship,
          'isPrimary': isPrimary,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'contact': data['contact'] ?? data['emergencyContacts']?.last};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to add contact'};
      }
    } catch (e) {
      print('Error in addEmergencyContact: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delete emergency contact
  Future<Map<String, dynamic>> deleteEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.emergencyContactsUrl}/$contactId'),
        headers: _getHeaders(userId),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to delete contact'};
      }
    } catch (e) {
      print('Error in deleteEmergencyContact: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Remove emergency contact
  Future<List<dynamic>> removeEmergencyContact(String contactId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.delete(
        Uri.parse('${ApiConfig.emergencyContactsUrl}/$contactId'),
        headers: _getHeaders(userId),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['emergencyContacts'];
      } else {
        throw Exception(data['error'] ?? 'Failed to remove contact');
      }
    } catch (e) {
      print('Error in removeEmergencyContact: $e');
      rethrow;
    }
  }

  /// Update FCM token on backend
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('Cannot update FCM token: User not logged in');
        return;
      }

      // Get user's phone number from storage
      final phone = await _storage.getPhoneNumber();
      if (phone == null) {
        print('Cannot update FCM token: Phone number not found');
        return;
      }

      print('Updating FCM token on backend...');
      
      // Call register endpoint to update token
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'phoneNumber': phone,
          'fcmToken': fcmToken,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('FCM token updated successfully');
      } else {
        print('Failed to update FCM token: ${data['error']}');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Update user settings
  Future<Map<String, dynamic>> updateSettings({
    bool? autoSendAlert,
    int? alertCountdown,
    bool? shareLocation,
    bool? sendSMSFallback,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final body = <String, dynamic>{};
      if (autoSendAlert != null) body['autoSendAlert'] = autoSendAlert;
      if (alertCountdown != null) body['alertCountdown'] = alertCountdown;
      if (shareLocation != null) body['shareLocation'] = shareLocation;
      if (sendSMSFallback != null) body['sendSMSFallback'] = sendSMSFallback;

      final response = await http.put(
        Uri.parse(ApiConfig.settingsUrl),
        headers: _getHeaders(userId),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['settings'];
      } else {
        throw Exception(data['error'] ?? 'Failed to update settings');
      }
    } catch (e) {
      print('Error in updateSettings: $e');
      rethrow;
    }
  }

  /// Create emergency alert
  Future<Map<String, dynamic>> createEmergencyAlert({
    required String userId,
    double? latitude,
    double? longitude,
    int? magnitude,
    String? message,
    String? address,
    String? deviceInfo,
    String? bluetoothDevice,
    Map<String, dynamic>? rawSensorData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.alertsUrl),
        headers: _getHeaders(userId),
        body: jsonEncode({
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
          'magnitude': magnitude,
          'message': message,
          'address': address,
          'deviceInfo': deviceInfo,
          'bluetoothDevice': bluetoothDevice,
          'rawSensorData': rawSensorData,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'alert': data['alert']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to create alert'};
      }
    } catch (e) {
      print('Error in createEmergencyAlert: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Cancel alert
  Future<Map<String, dynamic>> cancelAlert(String alertId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse('${ApiConfig.alertsUrl}/$alertId/cancel'),
        headers: _getHeaders(userId),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['alert'];
      } else {
        throw Exception(data['error'] ?? 'Failed to cancel alert');
      }
    } catch (e) {
      print('Error in cancelAlert: $e');
      rethrow;
    }
  }

  /// Get alert history
  Future<List<dynamic>> getAlertHistory({int page = 1, int limit = 20}) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('${ApiConfig.alertsUrl}?page=$page&limit=$limit'),
        headers: _getHeaders(userId),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['alerts'];
      } else {
        throw Exception(data['error'] ?? 'Failed to get alert history');
      }
    } catch (e) {
      print('Error in getAlertHistory: $e');
      rethrow;
    }
  }

  /// Get received notifications (where you were alerted)
  Future<Map<String, dynamic>> getReceivedNotifications({
    int page = 1,
    int limit = 20,
    String? status,
    String? firebaseToken,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alerts/notifications/received')
          .replace(queryParameters: queryParams);

      final token = firebaseToken ?? await _getFirebaseToken();
      
      final response = await http.get(
        uri,
        headers: _getHeaders(null, token),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'notifications': data['notifications'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch notifications',
        };
      }
    } catch (e) {
      print('Error in getReceivedNotifications: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get sent notifications (alerts YOU created)
  Future<Map<String, dynamic>> getSentNotifications({
    int page = 1,
    int limit = 20,
    String? firebaseToken,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alerts/notifications/sent')
          .replace(queryParameters: queryParams);

      final token = firebaseToken ?? await _getFirebaseToken();
      
      final response = await http.get(
        uri,
        headers: _getHeaders(null, token),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'notifications': data['notifications'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch sent notifications',
        };
      }
    } catch (e) {
      print('Error in getSentNotifications: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get all notifications (sent + received)
  Future<Map<String, dynamic>> getAllNotifications({
    int page = 1,
    int limit = 20,
    String? firebaseToken,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alerts/notifications/all')
          .replace(queryParameters: queryParams);

      final token = firebaseToken ?? await _getFirebaseToken();
      
      final response = await http.get(
        uri,
        headers: _getHeaders(null, token),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'notifications': data['notifications'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch notifications',
        };
      }
    } catch (e) {
      print('Error in getAllNotifications: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Helper method to get Firebase token
  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }
}
