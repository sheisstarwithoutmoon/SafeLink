import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callbacks
  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpenedApp;
  Function(String)? onTokenRefresh;

  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('FCM Permission status: ${settings.authorizationStatus}');

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'emergency_alerts', // id
        'Emergency Alerts', // name
        description: 'Notifications for emergency alerts from contacts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _storage.saveFcmToken(_fcmToken!);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _storage.saveFcmToken(newToken);
        onTokenRefresh?.call(newToken);
      });

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message opened app (from background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('Message opened app: ${message.messageId}');
        onMessageOpenedApp?.call(message);
      });

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.messageId}');
        onMessageOpenedApp?.call(initialMessage);
      }

    } catch (e) {
      print('Error initializing FCM: $e');
      rethrow;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    onMessageReceived?.call(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Extract alert data
    final userName = message.data['userName'] ?? 'Unknown';
    final userPhone = message.data['userPhoneNumber'] ?? 'Unknown';
    final latitude = message.data['latitude'];
    final longitude = message.data['longitude'];
    final severity = message.data['severity'] ?? 'high';
    
    // Build enhanced notification body
    String body = '${userName} may have been in an accident\n';
    body += 'Location: ${latitude ?? 'Unknown'}, ${longitude ?? 'Unknown'}\n';
    body += 'Severity: ${severity}\n';
    body += 'Tap to view details and navigate';
    
    const androidDetails = AndroidNotificationDetails(
      'emergency_alerts',
      'Emergency Alerts',
      channelDescription: 'Notifications for emergency alerts from contacts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Emergency Alert',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload with all alert data
    String payload = '';
    if (latitude != null && longitude != null) {
      payload = 'alert:${message.data['alertId'] ?? 'unknown'}|';
      payload += 'name:$userName|';
      payload += 'phone:$userPhone|';
      payload += 'lat:$latitude|';
      payload += 'lng:$longitude|';
      payload += 'severity:$severity|';
      payload += 'time:${DateTime.now().toIso8601String()}';
    }

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? '🚨 EMERGENCY ALERT',
      body,
      notificationDetails,
      payload: payload.isNotEmpty ? payload : null,
    );
  }

  void _onNotificationTapped(NotificationResponse response) async {
    print('Notification tapped: ${response.payload}');
    
    // Notification tap will trigger onMessageOpenedApp which shows the dialog
    // Payload is handled by the main app callback
  }

  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    _fcmToken = await _fcm.getToken();
    if (_fcmToken != null) {
      await _storage.saveFcmToken(_fcmToken!);
    }
    
    return _fcmToken;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    await _storage.clearFcmToken();
    _fcmToken = null;
    print('FCM token deleted');
  }
}
