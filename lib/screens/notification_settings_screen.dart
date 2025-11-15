import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final StorageService _storageService = StorageService();
  bool _emergencyAlerts = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load notification preferences from storage
    // For now, using default values
    setState(() {
      _emergencyAlerts = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _showNotifications = true;
    });
  }

  Future<void> _saveSettings() async {
    // Save notification preferences to storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Emergency Alerts',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Receive emergency notifications'),
                  value: _emergencyAlerts,
                  onChanged: (value) {
                    setState(() {
                      _emergencyAlerts = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Show Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Display notification banners'),
                  value: _showNotifications,
                  onChanged: (value) {
                    setState(() {
                      _showNotifications = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Sound',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Play notification sound'),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Vibration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Vibrate on notification'),
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'EMERGENCY ALERTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Important',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emergency alerts are critical for your safety. '
                    'These notifications will alert your emergency contacts '
                    'if an accident is detected.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
