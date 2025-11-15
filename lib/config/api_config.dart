class ApiConfig {
  // Production Backend URL (Render deployment)
  static const String baseUrl = 'https://saferide-backend-04w2.onrender.com';
  static const String apiUrl = '$baseUrl/api';
  
  // Socket.IO URL (uses WSS for secure WebSocket)
  static const String socketUrl = baseUrl;
  
  // API Endpoints
  static const String registerUrl = '$apiUrl/users/register';
  static const String profileUrl = '$apiUrl/users/profile';
  static const String emergencyContactsUrl = '$apiUrl/users/emergency-contacts';
  static const String settingsUrl = '$apiUrl/users/settings';
  static const String alertsUrl = '$apiUrl/alerts';
  
  // Timeouts (increased for Render cold starts)
  static const Duration connectionTimeout = Duration(seconds: 90);
  static const Duration receiveTimeout = Duration(seconds: 90);
}
