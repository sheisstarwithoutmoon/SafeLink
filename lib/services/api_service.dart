import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Map<String, String> _getHeaders([String? userId]) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (userId != null) {
      headers['x-user-id'] = userId;
    }
    
    return headers;
  }

  /// Register or login user
  Future<Map<String, dynamic>> registerUser({
    required String phoneNumber,
    String? name,
    String? fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'name': name,
          'fcmToken': fcmToken,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save user ID locally
        await _storage.saveUserId(data['user']['id']);
        return data;
      } else {
        throw Exception(data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Error in registerUser: $e');
      rethrow;
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
  Future<List<dynamic>> addEmergencyContact({
    required String phoneNumber,
    String? name,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse(ApiConfig.emergencyContactsUrl),
        headers: _getHeaders(userId),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'name': name,
          'relationship': relationship,
          'isPrimary': isPrimary,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['emergencyContacts'];
      } else {
        throw Exception(data['error'] ?? 'Failed to add contact');
      }
    } catch (e) {
      print('Error in addEmergencyContact: $e');
      rethrow;
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

  /// Create accident alert
  Future<Map<String, dynamic>> createAlert({
    required double latitude,
    required double longitude,
    int? magnitude,
    String? address,
    String? deviceInfo,
    String? bluetoothDevice,
    Map<String, dynamic>? rawSensorData,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse(ApiConfig.alertsUrl),
        headers: _getHeaders(userId),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'magnitude': magnitude,
          'address': address,
          'deviceInfo': deviceInfo,
          'bluetoothDevice': bluetoothDevice,
          'rawSensorData': rawSensorData,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['alert'];
      } else {
        throw Exception(data['error'] ?? 'Failed to create alert');
      }
    } catch (e) {
      print('Error in createAlert: $e');
      rethrow;
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
}
