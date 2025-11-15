import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _emergencyContactKey = 'emergency_contact';
  static const String _userIdKey = 'user_id';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _onboardingKey = 'onboarding_completed';

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<void> clearUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  Future<String?> getFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  Future<void> saveFcmToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<void> clearFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }

  Future<String?> getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone_number');
  }

  Future<void> savePhoneNumber(String phone) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phone);
  }

  Future<String> getEmergencyContact() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emergencyContactKey) ?? "";
  }

  Future<void> saveEmergencyContact(String contact) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emergencyContactKey, contact);
  }

  Future<void> clearEmergencyContact() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emergencyContactKey);
  }

  Future<bool> isOnboardingCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> saveOnboardingCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<void> saveLastNotification(String payload) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification', payload);
  }

  Future<String?> getLastNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_notification');
  }

  Future<void> clearLastNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification');
  }

  // Save notification to history
  Future<void> saveNotificationToHistory(Map<String, dynamic> notification) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Get existing notifications
    List<String> notifications = prefs.getStringList('notification_history') ?? [];
    
    // Add timestamp if not present
    if (!notification.containsKey('timestamp')) {
      notification['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    }
    
    // Add new notification at the beginning
    notifications.insert(0, jsonEncode(notification));
    
    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }
    
    await prefs.setStringList('notification_history', notifications);
  }

  // Get all notifications from history
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notification_history') ?? [];
    
    return notifications.map((notificationString) {
      try {
        return jsonDecode(notificationString) as Map<String, dynamic>;
      } catch (e) {
        print('Error decoding notification: $e');
        return <String, dynamic>{};
      }
    }).where((notification) => notification.isNotEmpty).toList();
  }

  // Clear notification history
  Future<void> clearNotificationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_history');
  }
}
