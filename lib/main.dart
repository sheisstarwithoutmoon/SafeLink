import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safe_ride/services/fcm_service.dart';
import 'package:safe_ride/services/socket_service.dart';
import 'package:safe_ride/services/bluetooth_service.dart';
import 'firebase_options.dart';
import 'screens/emergency_test_page.dart';

void main() {
  runApp(const SafeRideApp());
}

class SafeRideApp extends StatefulWidget {
  const SafeRideApp({Key? key}) : super(key: key);

  @override
  State<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends State<SafeRideApp> {
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
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
        await FcmService().initialize();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Ride - Emergency System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _error
          ? _ErrorScreen(message: _errorMessage)
          : _initialized
              ? const EmergencyTestPage()
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