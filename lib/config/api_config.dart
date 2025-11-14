class ApiConfig {
  // Backend API URL - Update this with your actual backend URL
  // Use your computer's IP address when testing on physical device
  // Use 'http://localhost:5000' when using Android emulator
  static const String baseUrl = 'http://192.168.17.113:5000';
  static const String apiUrl = '$baseUrl/api';
  
  // Socket.IO URL
  static const String socketUrl = baseUrl;
  
  // API Endpoints
  static const String registerUrl = '$apiUrl/users/register';
  static const String profileUrl = '$apiUrl/users/profile';
  static const String emergencyContactsUrl = '$apiUrl/users/emergency-contacts';
  static const String settingsUrl = '$apiUrl/users/settings';
  static const String alertsUrl = '$apiUrl/alerts';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
