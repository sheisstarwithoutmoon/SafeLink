import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/bluetooth_service.dart';

class EmergencyTestScreen extends StatefulWidget {
  final User user;

  const EmergencyTestScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EmergencyTestScreen> createState() => _EmergencyTestScreenState();
}

class _EmergencyTestScreenState extends State<EmergencyTestScreen> {
  final ApiService _apiService = ApiService();
  final BluetoothService _bluetoothService = BluetoothService();

  bool _isLoading = false;
  bool _isCountingDown = false;
  int _countdown = 15;
  Timer? _countdownTimer;
  StreamSubscription? _bluetoothSubscription;
  List<String> _recentBluetoothMessages = [];

  @override
  void initState() {
    super.initState();
    _setupBluetoothListener();
  }

  void _setupBluetoothListener() {
    _bluetoothSubscription = _bluetoothService.dataStream.listen((data) {
      // Add to recent messages for display (only keep last 10)
      setState(() {
        _recentBluetoothMessages.insert(0, data);
        if (_recentBluetoothMessages.length > 10) {
          _recentBluetoothMessages.removeLast();
        }
      });
      
      // Check for accident detection
      if (data.contains('ACCIDENT') || data.contains('CRASH') || data.contains('ALERT')) {
        final magnitudeMatch = RegExp(r'INTENSITY:\s*(\d+)').firstMatch(data);
        final magnitude = magnitudeMatch != null
            ? int.tryParse(magnitudeMatch.group(1)!) ?? 0
            : 0;
        
        if (!_isCountingDown) {
          _startCountdown();
        }
      }
    });
  }

  void _startCountdown() {
    if (_isCountingDown) return;

    setState(() {
      _isCountingDown = true;
      _countdown = 15;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _createEmergencyAlert();
      }
    });

    _showCountdownDialog();
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 15;
    });
    Navigator.of(context).pop();
  }

  void _showCountdownDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.emergencyRed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing warning icon
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          size: 64,
                          color: AppTheme.emergencyRed,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted && _isCountingDown) {
                      setState(() {});
                    }
                  },
                ),

                const SizedBox(height: 48),

                // Emergency text
                const Text(
                  'ACCIDENT DETECTED',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Sending alert to emergency contacts',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Countdown timer
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Cancel button
                CustomButton(
                  text: 'I\'m OK - Cancel Alert',
                  onPressed: _cancelCountdown,
                  type: CustomButtonType.secondary,
                  icon: Icons.close,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createEmergencyAlert() async {
    Navigator.of(context).pop(); // Close countdown dialog

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Error getting location: $e');
      }

      // Create alert
      final response = await _apiService.createEmergencyAlert(
        userId: widget.user.id,
        latitude: position?.latitude,
        longitude: position?.longitude,
        message: 'Accident detected by Safe Ride system',
      );

      if (response['success']) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successGreen),
                const SizedBox(width: 12),
                const Text('Alert Sent'),
              ],
            ),
            content: Text(
              'Emergency contacts have been notified with your location.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isCountingDown = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Test'),
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: AppTheme.primaryAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.emergencyRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.emergencyRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.emergencyRed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will send a real emergency alert to your contacts',
                      style: TextStyle(color: AppTheme.emergencyRed),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Test button
            Text(
              'Manual Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate an accident detection and test the emergency alert system',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Trigger Emergency Alert',
              onPressed: _isLoading ? null : _startCountdown,
              type: CustomButtonType.danger,
              icon: Icons.warning_rounded,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 48),

            // Bluetooth status
            Text(
              'Automatic Detection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'The system is listening for accident signals from your connected Bluetooth device',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _bluetoothService.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: _bluetoothService.isConnected
                        ? AppTheme.successGreen
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _bluetoothService.connectedDevice?.name ??
                          'No device connected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bluetoothSubscription?.cancel();
    super.dispose();
  }
}
