import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';
import '../services/bluetooth_service.dart';
import 'bluetooth_devices_page.dart';

class EmergencyTestPage extends StatefulWidget {
  const EmergencyTestPage({Key? key}) : super(key: key);

  @override
  State<EmergencyTestPage> createState() => _EmergencyTestPageState();
}

class _EmergencyTestPageState extends State<EmergencyTestPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final FcmService _fcmService = FcmService();
  final StorageService _storageService = StorageService();
  final BluetoothService _bluetoothService = BluetoothService();
  
  bool isLoading = false;
  bool isRegistered = false;
  String? userId;
  String? fcmToken;
  List<dynamic> emergencyContacts = [];
  String? currentAlertId;
  Map<String, dynamic>? lastReceivedAlert;
  
  String statusMessage = "Not connected";
  Color statusColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
    _setupSocketListeners();
    _setupFcmListeners();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _contactPhoneController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _checkRegistration() async {
    userId = await _storageService.getUserId();
    fcmToken = await _fcmService.getToken();
    
    setState(() {
      isRegistered = userId != null;
      statusColor = _socketService.isConnected ? Colors.green : Colors.orange;
      statusMessage = _socketService.isConnected 
          ? "Connected to backend" 
          : "Connecting to backend...";
    });

    if (isRegistered) {
      await _loadProfile();
    }
  }

  void _setupSocketListeners() {
    _socketService.onConnected = () {
      setState(() {
        statusColor = Colors.green;
        statusMessage = "✓ Connected to backend";
      });
    };

    _socketService.onDisconnected = () {
      setState(() {
        statusColor = Colors.red;
        statusMessage = "✗ Disconnected from backend";
      });
    };

    _socketService.onEmergencyAlert = (data) {
      setState(() {
        lastReceivedAlert = data;
      });
      _showAlertDialog(data);
    };

    _socketService.onAlertSent = (alertId, message) {
      _showMessage("✅ $message", isError: false);
    };

    _socketService.onAlertCancelled = (alertId) {
      setState(() {
        currentAlertId = null;
      });
      _showMessage("Alert cancelled", isError: false);
    };
  }

  void _setupFcmListeners() {
    _fcmService.onMessageReceived = (message) {
      print("FCM Message: ${message.notification?.title}");
      _showMessage("📱 ${message.notification?.title}", isError: false);
    };

    _fcmService.onMessageOpenedApp = (message) {
      print("Opened from notification: ${message.data}");
    };
  }

  Future<void> _loadProfile() async {
    try {
      var profile = await _apiService.getProfile();
      setState(() {
        emergencyContacts = profile['emergencyContacts'] ?? [];
        _nameController.text = profile['name'] ?? '';
        _phoneController.text = profile['phoneNumber'] ?? '';
      });
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  Future<void> _registerUser() async {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage("Please enter phone number");
      return;
    }

    setState(() => isLoading = true);

    try {
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+')) {
        if (phone.length == 10) {
          phone = '+91$phone'; // Add India country code
        } else {
          _showMessage("Use format: +916261795658 or 10 digits");
          return;
        }
      }

      var result = await _apiService.registerUser(
        phoneNumber: phone,
        name: _nameController.text.trim(),
        fcmToken: fcmToken,
      );

      setState(() {
        isRegistered = true;
        userId = result['user']['id'];
        emergencyContacts = result['user']['emergencyContacts'] ?? [];
      });

      // Reconnect socket with new user ID
      await _socketService.connect();

      _showMessage("✅ Registration successful!", isError: false);
    } catch (e) {
      _showMessage("❌ Registration failed: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addEmergencyContact() async {
    if (_contactPhoneController.text.trim().isEmpty) {
      _showMessage("Please enter contact phone number");
      return;
    }

    setState(() => isLoading = true);

    try {
      String phone = _contactPhoneController.text.trim();
      if (!phone.startsWith('+')) {
        if (phone.length == 10) {
          phone = '+91$phone';
        } else {
          _showMessage("Use format: +919876543210 or 10 digits");
          return;
        }
      }

      var contacts = await _apiService.addEmergencyContact(
        phoneNumber: phone,
        name: _contactNameController.text.trim(),
        relationship: 'Emergency Contact',
        isPrimary: emergencyContacts.isEmpty,
      );

      setState(() {
        emergencyContacts = contacts;
        _contactPhoneController.clear();
        _contactNameController.clear();
      });

      _showMessage("✅ Contact added!", isError: false);
    } catch (e) {
      _showMessage("❌ Failed: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createTestAlert() async {
    if (!isRegistered) {
      _showMessage("Please register first!");
      return;
    }

    if (emergencyContacts.isEmpty) {
      _showMessage("Please add emergency contacts first!");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create alert via API
      var alert = await _apiService.createAlert(
        latitude: position.latitude,
        longitude: position.longitude,
        magnitude: 85, // Test magnitude
        address: 'Test Location',
        deviceInfo: 'Test Device',
        bluetoothDevice: 'HC-05 Test',
      );

      setState(() {
        currentAlertId = alert['id'];
      });

      // Emit via Socket.IO
      _socketService.createEmergency(
        alertId: alert['id'],
        latitude: position.latitude,
        longitude: position.longitude,
        magnitude: 85,
        address: 'Test Location',
      );

      _showMessage("🚨 Test alert created! Countdown: 15s", isError: false);
      
      // Start countdown dialog
      _showCountdownDialog();
    } catch (e) {
      _showMessage("❌ Failed to create alert: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelAlert() async {
    if (currentAlertId == null) return;

    try {
      await _apiService.cancelAlert(currentAlertId!);
      _socketService.cancelEmergency(currentAlertId!);
      
      setState(() {
        currentAlertId = null;
      });

      Navigator.of(context).pop(); // Close countdown dialog
      _showMessage("✅ Alert cancelled!", isError: false);
    } catch (e) {
      _showMessage("❌ Failed to cancel: $e");
    }
  }

  void _showCountdownDialog() {
    int countdown = 15;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Start countdown
          if (countdown > 0) {
            Future.delayed(const Duration(seconds: 1), () {
              if (countdown > 0) {
                setDialogState(() => countdown--);
              } else {
                Navigator.of(context).pop();
                _showMessage("🚨 Alert sent to emergency contacts!", isError: false);
              }
            });
          }

          return AlertDialog(
            title: const Text("🚨 Emergency Alert"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$countdown",
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Alert will be sent in:",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: _cancelAlert,
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel Alert"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAlertDialog(Map<String, dynamic> alertData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text("Emergency Alert!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${alertData['userName'] ?? 'Unknown'}"),
            Text("Phone: ${alertData['userPhone'] ?? 'Unknown'}"),
            const SizedBox(height: 8),
            Text("Location: ${alertData['latitude']}, ${alertData['longitude']}"),
            Text("Severity: ${alertData['severity'] ?? 'Unknown'}"),
            const SizedBox(height: 8),
            Text("Time: ${alertData['timestamp'] ?? DateTime.now()}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backend Emergency Test"),
        actions: [
          // Bluetooth button
          IconButton(
            icon: Icon(
              _bluetoothService.isConnected 
                ? Icons.bluetooth_connected 
                : Icons.bluetooth,
              color: _bluetoothService.isConnected ? Colors.green : null,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothDevicesPage(),
                ),
              );
            },
            tooltip: _bluetoothService.isConnected 
              ? 'Bluetooth Connected' 
              : 'Connect Bluetooth Device',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  statusMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "New Backend System",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "✓ No SMS costs - FREE push notifications\n"
                      "✓ Real-time location updates via Socket.IO\n"
                      "✓ 15-second countdown to cancel false alerts\n"
                      "✓ FCM Token: ${fcmToken?.substring(0, 20) ?? 'Loading'}...",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Registration Section
            if (!isRegistered) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "1. Register User",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Your Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Your Phone Number",
                          hintText: "+916261795658 or 10 digits",
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _registerUser,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.app_registration),
                          label: Text(isLoading ? "Registering..." : "Register"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // User Info
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Registered User",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Name: ${_nameController.text}"),
                      Text("Phone: ${_phoneController.text}"),
                      Text("User ID: ${userId?.substring(0, 8)}..."),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Add Emergency Contact
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "2. Add Emergency Contact",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contactNameController,
                        decoration: const InputDecoration(
                          labelText: "Contact Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contactPhoneController,
                        decoration: const InputDecoration(
                          labelText: "Contact Phone",
                          hintText: "+919876543210 or 10 digits",
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _addEmergencyContact,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Contact"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Contacts List
              if (emergencyContacts.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Emergency Contacts (${emergencyContacts.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...emergencyContacts.map((contact) => ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(contact['name'] ?? 'Unknown'),
                          subtitle: Text(contact['phoneNumber'] ?? ''),
                          trailing: contact['isPrimary'] == true
                              ? const Chip(
                                  label: Text("Primary"),
                                  backgroundColor: Colors.orange,
                                )
                              : null,
                        )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Create Alert Button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _createTestAlert,
                    icon: const Icon(Icons.warning, size: 32),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "🚨 CREATE TEST ALERT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Last Received Alert
              if (lastReceivedAlert != null) ...[
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.notifications_active, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "Last Received Alert",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("From: ${lastReceivedAlert!['userName']}"),
                        Text("Phone: ${lastReceivedAlert!['userPhone']}"),
                        Text("Severity: ${lastReceivedAlert!['severity']}"),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
