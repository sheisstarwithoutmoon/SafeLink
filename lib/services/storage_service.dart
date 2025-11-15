import 'package:shared_preferences/shared_preferences.dart';

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
}
