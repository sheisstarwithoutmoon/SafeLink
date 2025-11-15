import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/status_indicator.dart';
import '../services/bluetooth_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'emergency_contacts_screen.dart';
import 'bluetooth_connection_screen.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  
  ConnectionStatus _bluetoothStatus = ConnectionStatus.disconnected;
  StreamSubscription? _bluetoothDataSubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatuses();
    _setupListeners();
    _setupBluetoothAccidentDetection();
  }

  void _checkConnectionStatuses() {
    // Check Bluetooth status
    setState(() {
      _bluetoothStatus = _bluetoothService.isConnected 
          ? ConnectionStatus.connected 
          : ConnectionStatus.disconnected;
    });
  }

  void _setupListeners() {
    // Listen to Bluetooth connection changes
    _bluetoothService.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _bluetoothStatus = state 
              ? ConnectionStatus.connected 
              : ConnectionStatus.disconnected;
        });
      }
    });
  }

  void _setupBluetoothAccidentDetection() {
    // Listen to Bluetooth data for accident detection from Arduino
    _bluetoothDataSubscription = _bluetoothService.dataStream.listen((data) {
      // Check for accident keywords
      if (data.contains('ACCIDENT') || data.contains('CRASH') || data.contains('ALERT')) {
        // Extract magnitude/intensity if available
        int magnitude = 0;
        final intensityMatch = RegExp(r'INTENSITY:\s*(\d+)').firstMatch(data);
        final magnitudeMatch = RegExp(r'MAGNITUDE:\s*(\d+)').firstMatch(data);
        
        if (intensityMatch != null) {
          magnitude = int.tryParse(intensityMatch.group(1)!) ?? 0;
        } else if (magnitudeMatch != null) {
          magnitude = int.tryParse(magnitudeMatch.group(1)!) ?? 0;
        }
        
        // Trigger emergency alert automatically
        _handleAccidentDetected(magnitude);
      }
    });
  }

  void _handleAccidentDetected(int magnitude) {
    if (!mounted) return;

    // Show immediate alert
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AccidentDetectedDialog(
        user: widget.user,
        magnitude: magnitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.name,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              
              const SizedBox(height: 8),

              Text(
                'Stay Safe',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Feature cards
              _buildFeatureCard(
                icon: Icons.contacts,
                title: 'Emergency Contacts',
                description: '${widget.user.emergencyContacts.length} contacts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyContactsScreen(user: widget.user),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                icon: Icons.bluetooth,
                title: 'Device Connection',
                description: _bluetoothStatus == ConnectionStatus.connected 
                    ? 'Connected' 
                    : 'Not connected',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BluetoothConnectionScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Emergency status message
              Center(
                child: Text(
                  'Automatic Protection Active',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Monitoring for accidents 24/7',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothDataSubscription?.cancel();
    super.dispose();
  }
}

// Accident Detected Dialog with Countdown
class _AccidentDetectedDialog extends StatefulWidget {
  final User user;
  final int magnitude;

  const _AccidentDetectedDialog({
    required this.user,
    required this.magnitude,
  });

  @override
  State<_AccidentDetectedDialog> createState() => _AccidentDetectedDialogState();
}

class _AccidentDetectedDialogState extends State<_AccidentDetectedDialog> {
  int _countdown = 15;
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _sendAlert();
      }
    });
  }

  Future<void> _sendAlert() async {
    try {
      // Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create alert via API (backend will send FCM notifications)
      final result = await _apiService.createEmergencyAlert(
        userId: widget.user.id,
        latitude: position.latitude,
        longitude: position.longitude,
        magnitude: widget.magnitude,
        message: 'Accident detected by Safe Ride system',
      );

      if (result['success']) {
        var alert = result['alert'];
        print('Alert created successfully: ${alert['_id'] ?? alert['id']}');
        
        // Try to send via Socket.IO for real-time updates (optional)
        try {
          // Ensure socket is connected
          if (!_socketService.isConnected) {
            print('Reconnecting socket...');
            await _socketService.connect();
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          if (_socketService.isConnected) {
            _socketService.createEmergency(
              alertId: alert['_id'] ?? alert['id'],
              latitude: position.latitude,
              longitude: position.longitude,
              magnitude: widget.magnitude,
              address: 'Detected Location',
            );
            print('Socket emergency event sent');
          } else {
            print('Socket still not connected, skipping real-time update');
          }
        } catch (socketError) {
          print('Socket error (non-critical): $socketError');
          // Continue - alert was created via API, Socket.IO is optional
        }

        if (!mounted) return;
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contacts notified'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to create alert');
      }
    } catch (e) {
      print('Error sending alert: $e');
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelAlert() {
    _timer?.cancel();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency alert cancelled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final iconSize = isSmallScreen ? 100.0 : 120.0;
    final titleSize = isSmallScreen ? 24.0 : 32.0;
    final bodySize = isSmallScreen ? 14.0 : 18.0;
    final countdownSize = isSmallScreen ? 180.0 : 200.0;
    final countdownTextSize = isSmallScreen ? 80.0 : 96.0;
    
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppTheme.emergencyRed,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing warning icon
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.9, end: 1.1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    builder: (context, double scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.car_crash,
                            size: iconSize * 0.53,
                            color: AppTheme.emergencyRed,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (mounted) setState(() {});
                    },
                  ),

                  SizedBox(height: isSmallScreen ? 32 : 48),

                  Text(
                    'ACCIDENT DETECTED',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 32),
                    child: Text(
                      'Notifying emergency contacts with your location',
                      style: TextStyle(
                        fontSize: bodySize,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Countdown
                  Container(
                    width: countdownSize,
                    height: countdownSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: TextStyle(
                          fontSize: countdownTextSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  Text(
                    'seconds',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      color: Colors.white70,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Cancel button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 32),
                    child: ElevatedButton(
                      onPressed: _cancelAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.emergencyRed,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 24 : 48,
                          vertical: isSmallScreen ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: isSmallScreen ? 24 : 28),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Flexible(
                            child: Text(
                              'I\'m OK - Cancel Alert',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
