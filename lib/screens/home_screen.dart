import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/bluetooth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'notification_history_screen.dart';
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
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  StreamSubscription? _bluetoothDataSubscription;
  StreamSubscription? _bluetoothConnectionSubscription;
  bool _isMonitoring = false;
  bool _isBluetoothConnected = false;
  String _bluetoothDataBuffer = '';
  DateTime? _lastAccidentDetection;
  
  // Real stats
  int _alertsSent = 0;
  int _alertsReceived = 0;
  int _emergencyContactsCount = 0;
  int _daysActive = 0;
  String _lastAlertTime = 'Never';
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadRealStats();
    _setupBluetoothListener();
    _setupBluetoothConnectionListener();
  }

  Future<void> _loadRealStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Fetch both sent and received notifications from backend API
      final sentResponse = await _apiService.getSentNotifications(limit: 100);
      final receivedResponse = await _apiService.getReceivedNotifications(limit: 100);

      int sentCount = 0;
      int receivedCount = 0;
      int? firstTimestamp;
      int? lastTimestamp;

      // Process sent notifications
      if (sentResponse['success'] == true) {
        final sentNotifications = (sentResponse['notifications'] as List<dynamic>?) ?? [];
        sentCount = sentNotifications.length;

        for (var notification in sentNotifications) {
          final createdAt = notification['createdAt'] as String?;
          if (createdAt != null) {
            try {
              final timestamp = DateTime.parse(createdAt).millisecondsSinceEpoch;
              if (firstTimestamp == null || timestamp < firstTimestamp) {
                firstTimestamp = timestamp;
              }
              if (lastTimestamp == null || timestamp > lastTimestamp) {
                lastTimestamp = timestamp;
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
          }
        }
      }

      // Process received notifications
      if (receivedResponse['success'] == true) {
        final receivedNotifications = (receivedResponse['notifications'] as List<dynamic>?) ?? [];
        receivedCount = receivedNotifications.length;

        for (var notification in receivedNotifications) {
          final createdAt = notification['createdAt'] as String?;
          if (createdAt != null) {
            try {
              final timestamp = DateTime.parse(createdAt).millisecondsSinceEpoch;
              if (firstTimestamp == null || timestamp < firstTimestamp) {
                firstTimestamp = timestamp;
              }
              if (lastTimestamp == null || timestamp > lastTimestamp) {
                lastTimestamp = timestamp;
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
          }
        }
      }

      // Calculate days active from first notification
      int daysActive = 0;
      if (firstTimestamp != null) {
        final firstDate = DateTime.fromMillisecondsSinceEpoch(firstTimestamp);
        final now = DateTime.now();
        daysActive = now.difference(firstDate).inDays;
      }

      // Format last alert time (most recent notification)
      String lastAlertFormatted = 'Never';
      if (lastTimestamp != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
        final now = DateTime.now();
        final difference = now.difference(lastDate);

        if (difference.inMinutes < 1) {
          lastAlertFormatted = 'Just now';
        } else if (difference.inHours < 1) {
          lastAlertFormatted = '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          lastAlertFormatted = '${difference.inHours}h ago';
        } else if (difference.inDays < 7) {
          lastAlertFormatted = '${difference.inDays}d ago';
        } else {
          lastAlertFormatted = '${(difference.inDays / 7).floor()}w ago';
        }
      }

      // Get emergency contacts count from user object
      int contactsCount = widget.user.emergencyContacts.length;

      setState(() {
        _alertsSent = sentCount;
        _alertsReceived = receivedCount;
        _emergencyContactsCount = contactsCount;
        _daysActive = daysActive;
        _lastAlertTime = lastAlertFormatted;
        _isLoadingStats = false;
      });

      print('Stats loaded: Sent=$sentCount, Received=$receivedCount, Contacts=$contactsCount, Days=$daysActive');
    } catch (e) {
      print('Error loading stats from API: $e');
      
      // Fallback to local storage if API fails
      try {
        final notifications = await _storageService.getNotificationHistory();
        
        int sentCount = 0;
        int receivedCount = 0;
        int? firstTimestamp;
        int? lastTimestamp;

        for (var notification in notifications) {
          final type = notification['type'] as String?;
          final timestamp = notification['timestamp'] as int?;

          if (type == 'sent') {
            sentCount++;
          } else {
            receivedCount++;
          }

          if (timestamp != null) {
            if (firstTimestamp == null || timestamp < firstTimestamp) {
              firstTimestamp = timestamp;
            }
            if (lastTimestamp == null || timestamp > lastTimestamp) {
              lastTimestamp = timestamp;
            }
          }
        }

        int daysActive = 0;
        if (firstTimestamp != null) {
          final firstDate = DateTime.fromMillisecondsSinceEpoch(firstTimestamp);
          final now = DateTime.now();
          daysActive = now.difference(firstDate).inDays;
        }

        String lastAlertFormatted = 'Never';
        if (lastTimestamp != null) {
          final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
          final now = DateTime.now();
          final difference = now.difference(lastDate);

          if (difference.inMinutes < 1) {
            lastAlertFormatted = 'Just now';
          } else if (difference.inHours < 1) {
            lastAlertFormatted = '${difference.inMinutes}m ago';
          } else if (difference.inDays < 1) {
            lastAlertFormatted = '${difference.inHours}h ago';
          } else if (difference.inDays < 7) {
            lastAlertFormatted = '${difference.inDays}d ago';
          } else {
            lastAlertFormatted = '${(difference.inDays / 7).floor()}w ago';
          }
        }

        int contactsCount = widget.user.emergencyContacts.length;

        setState(() {
          _alertsSent = sentCount;
          _alertsReceived = receivedCount;
          _emergencyContactsCount = contactsCount;
          _daysActive = daysActive;
          _lastAlertTime = lastAlertFormatted;
          _isLoadingStats = false;
        });

        print('Stats loaded from local storage (fallback): Sent=$sentCount, Received=$receivedCount');
      } catch (storageError) {
        print('Error loading from local storage: $storageError');
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bluetoothDataSubscription?.cancel();
    _bluetoothConnectionSubscription?.cancel();
    super.dispose();
  }

  void _setupBluetoothConnectionListener() {
    _bluetoothConnectionSubscription = _bluetoothService.connectionStateStream.listen((isConnected) {
      setState(() {
        _isBluetoothConnected = isConnected;
      });
    });
  }

  void _setupBluetoothListener() {
    _bluetoothDataSubscription = _bluetoothService.dataStream.listen((data) {
      // Add data to buffer
      _bluetoothDataBuffer += data.toLowerCase();
      
      // Keep buffer to reasonable size (last 500 characters)
      if (_bluetoothDataBuffer.length > 500) {
        _bluetoothDataBuffer = _bluetoothDataBuffer.substring(_bluetoothDataBuffer.length - 500);
      }
      
      // Wait for Arduino's timer to complete before showing app dialog
      // Only trigger when Arduino confirms: "ACCIDENT ALERT" or "alert timer: 0s"
      if (_bluetoothDataBuffer.contains('accident alert') || 
          _bluetoothDataBuffer.contains('alert timer: 0s')) {
        
        // Prevent multiple triggers within 20 seconds
        final now = DateTime.now();
        if (_lastAccidentDetection != null) {
          final timeSinceLastDetection = now.difference(_lastAccidentDetection!);
          if (timeSinceLastDetection.inSeconds < 20) {
            print('⏸️ Accident detected but ignoring (cooldown: ${timeSinceLastDetection.inSeconds}s)');
            return;
          }
        }
        
        print('ARDUINO TIMER COMPLETED! Showing app countdown dialog...');
        _lastAccidentDetection = now;
        _bluetoothDataBuffer = ''; // Clear buffer after detection
        _handleAccidentDetection();
      }
    });
  }

  Future<void> _handleAccidentDetection() async {
    if (_isMonitoring) return;
    
    setState(() {
      _isMonitoring = true;
    });

    // Show countdown dialog
    _showCountdownDialog();
  }

  void _showCountdownDialog() {
    int countdown = 15;
    bool cancelled = false;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              if (countdown > 0 && !cancelled) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (!cancelled && countdown > 0) {
                    setState(() {
                      countdown--;
                    });
                  }
                  if (countdown == 0 && !cancelled) {
                    Navigator.of(context).pop();
                    _sendAlert();
                  }
                });
              }

              return Material(
                color: Colors.red.shade600,
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // Pulsing warning icon
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.8, end: 1.2),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, double scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.warning_rounded,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                                onEnd: () {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Main title
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'ACCIDENT DETECTED!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Countdown circle
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 6,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$countdown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'seconds',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Message
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Emergency alert will be sent to all contacts',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Location, time, and emergency details will be shared',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Cancel button
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      cancelled = true;
                                      Navigator.of(context).pop();
                                      this.setState(() {
                                        _isMonitoring = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red.shade700,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                    ),
                                    child: const Text(
                                      "I'M SAFE - CANCEL ALERT",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ).then((_) {
      setState(() {
        _isMonitoring = false;
      });
    });
  }

  Future<void> _sendAlert() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      
      final result = await _apiService.createEmergencyAlert(
        userId: widget.user.id,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result['success']) {
        // Save sent alert to local history with 'sent' type
        final sentAlertData = {
          'title': 'Alert Sent',
          'body': 'Emergency alert sent to all contacts',
          'userName': widget.user.name,
          'userPhone': widget.user.phone,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'severity': 'high',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'time': DateTime.now().toIso8601String(),
          'type': 'sent', // Mark as sent by user
          'status': 'delivered',
        };
        await StorageService().saveNotificationToHistory(sentAlertData);
        
        // Reload stats after sending alert
        _loadRealStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency alert sent successfully\nLocation: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending alert: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isMonitoring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Ride'),
        elevation: 0,
        actions: [
          // Bluetooth connection icon
          IconButton(
            icon: Icon(
              _isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: _isBluetoothConnected ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothConnectionScreen(),
                ),
              );
            },
            tooltip: _isBluetoothConnected ? 'Helmet Connected' : 'Connect Helmet',
          ),
          // Notifications icon
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryScreen(),
                ),
              );
              // Reload stats when returning from notification history
              _loadRealStats();
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRealStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Protection Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Safety Stats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingStats
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.send_rounded,
                                    title: 'Alerts Sent',
                                    value: '$_alertsSent',
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.notifications_active,
                                    title: 'Alerts Received',
                                    value: '$_alertsReceived',
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.people,
                                    title: 'Emergency Contacts',
                                    value: '$_emergencyContactsCount',
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.calendar_today,
                                    title: 'Days Active',
                                    value: '$_daysActive',
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.teal.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.access_time,
                                      color: Colors.teal,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Last Alert',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _lastAlertTime,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Safety Tips Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Safety Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSafetyTip(
                    icon: Icons.speed,
                    title: 'Maintain Safe Speed',
                    description: 'Always ride within speed limits. Reduce speed in rain or traffic.',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildSafetyTip(
                    icon: Icons.remove_red_eye,
                    title: 'Stay Alert',
                    description: 'Keep your eyes on the road. Avoid distractions like phones.',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildSafetyTip(
                    icon: Icons.wb_sunny,
                    title: 'Check Weather',
                    description: 'Avoid riding in extreme weather. Plan your route accordingly.',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildSafetyTip(
                    icon: Icons.build,
                    title: 'Regular Maintenance',
                    description: 'Check brakes, tires, and lights regularly for optimal safety.',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Did You Know Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade50,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Did You Know?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wearing a helmet reduces the risk of head injury by 69% and death by 42% in motorcycle accidents.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Always ensure your helmet is properly fastened before riding!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
