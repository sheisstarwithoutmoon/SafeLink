import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safe_ride/services/fcm_service.dart';
import 'package:safe_ride/services/socket_service.dart';
import 'package:safe_ride/services/bluetooth_service.dart';
import 'package:safe_ride/services/api_service.dart';
import 'package:safe_ride/services/storage_service.dart';
import 'package:safe_ride/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'screens/app_initializer.dart';

// Global key for navigation from background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const SafeRideApp());
}

class SafeRideApp extends StatefulWidget {
  const SafeRideApp({Key? key}) : super(key: key);

  @override
  State<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends State<SafeRideApp> with WidgetsBindingObserver {
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - reconnecting Socket.IO...');
        _reconnectSocket();
        break;
      case AppLifecycleState.paused:
        print('📱 App paused');
        break;
      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;
      case AppLifecycleState.detached:
        print('📱 App detached');
        break;
      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
    }
  }

  Future<void> _reconnectSocket() async {
    try {
      // Only reconnect if user is logged in
      final userId = await StorageService().getUserId();
      if (userId != null) {
        await SocketService().connect();
      }
    } catch (e) {
      print('⚠️ Socket reconnection failed: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();
      
      print('🚀 Initializing Safe Ride...');
      
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized');
      
      // Initialize Bluetooth (allow to fail gracefully)
      try {
        final bluetoothResult = await BluetoothService().initialize();
        if (bluetoothResult['success']) {
          print('✅ Bluetooth initialized');
        } else {
          print('⚠️ Bluetooth initialization incomplete: ${bluetoothResult['error']}');
        }
      } catch (e) {
        print('⚠️ Bluetooth initialization failed: $e');
        // Continue anyway - user can enable later
      }
      
      // Initialize FCM (allow to fail gracefully)
      try {
        final fcmService = FcmService();
        
        // Set up token refresh callback
        fcmService.onTokenRefresh = (newToken) async {
          print('🔄 FCM token refreshed, updating backend...');
          try {
            await ApiService().updateFcmToken(newToken);
          } catch (e) {
            print('⚠️ Failed to update FCM token on backend: $e');
          }
        };
        
        // Set up message received callback to show dialog
        fcmService.onMessageReceived = (message) {
          _showEmergencyAlertDialog(message.data);
        };
        
        // Set up message opened app callback to show dialog
        fcmService.onMessageOpenedApp = (message) {
          _showEmergencyAlertDialog(message.data);
        };
        
        await fcmService.initialize();
        print('✅ FCM initialized');
      } catch (e) {
        print('⚠️ FCM initialization failed: $e');
        // Continue anyway
      }
      
      // Connect to Socket.IO (non-blocking - allow to fail gracefully)
      SocketService().connect().then((_) {
        print('✅ Socket.IO connected');
      }).catchError((e) {
        print('⚠️ Socket.IO connection failed: $e');
        // Continue anyway - user can connect later after registration
      });
      
      setState(() {
        _initialized = true;
      });
      print('✅ App initialized successfully');
      
    } catch (e) {
      print('❌ Initialization error: $e');
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _showEmergencyAlertDialog(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final userName = data['userName'] ?? 'Unknown';
    final userPhone = data['userPhoneNumber'] ?? 'Unknown';
    final latitude = data['latitude'] ?? '0';
    final longitude = data['longitude'] ?? '0';
    final severity = data['severity'] ?? 'high';
    final time = DateTime.now().toIso8601String();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(dialogContext).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: severity == 'critical' ? Colors.red : Colors.orange,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Emergency Alert!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogRow('From:', userName),
                      const SizedBox(height: 8),
                      _buildDialogRow('Phone:', userPhone),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _openMaps(latitude, longitude),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Location:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.open_in_new, size: 16, color: Colors.blue.shade700),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$latitude, $longitude',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to open in Maps',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDialogRow('Severity:', severity),
                      const SizedBox(height: 8),
                      _buildDialogRow('Time:', _formatDialogTime(time)),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDialogTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTime;
    }
  }

  Future<void> _openMaps(String lat, String lng) async {
    try {
      print('🗺️ Opening maps with coordinates: $lat, $lng');
      
      // Try Google Maps app first with intent URL (works best on Android)
      final googleMapsUrl = 'google.navigation:q=$lat,$lng';
      final googleMapsUri = Uri.parse(googleMapsUrl);
      
      if (await canLaunchUrl(googleMapsUri)) {
        print('✅ Launching Google Maps app...');
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Fallback to geo: URL for any maps app
      final geoUrl = 'geo:$lat,$lng?q=$lat,$lng';
      final geoUri = Uri.parse(geoUrl);
      
      if (await canLaunchUrl(geoUri)) {
        print('✅ Launching with geo: URL...');
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Last fallback: web URL
      final webUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final webUri = Uri.parse(webUrl);
      
      print('✅ Launching web maps...');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      
    } catch (e) {
      print('❌ Error opening maps: $e');
      // Show error message to user
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Safe Ride - Emergency System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _error
          ? _ErrorScreen(message: _errorMessage)
          : _initialized
              ? const AppInitializer()
              : const _LoadingScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flutter logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.car_crash,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Safe Ride',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  
  const _ErrorScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}