import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import 'emergency_contacts_screen.dart';
import 'bluetooth_connection_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'help_support_screen.dart';
import 'app_initializer.dart';

class SettingsScreen extends StatelessWidget {
  final User user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Settings Options
          _buildSettingsTile(
            context,
            icon: Icons.contacts_rounded,
            title: 'Emergency Contacts',
            subtitle: '${user.emergencyContacts.length} contact(s)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyContactsScreen(user: user),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.bluetooth_rounded,
            title: 'Bluetooth Connection',
            subtitle: 'Connect to helmet device',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothConnectionScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.shield_rounded,
            title: 'Privacy & Safety',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.help_rounded,
            title: 'Help & Support',
            subtitle: 'Get help or contact us',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.info_rounded,
            title: 'About',
            subtitle: 'Version 3.4.3',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Safe Ride',
                applicationVersion: '3.4.3',
                applicationIcon: Icon(
                  Icons.car_crash,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                children: [
                  const Text(
                    'Emergency response system for motorcycle riders. '
                    'Automatically detects accidents and alerts emergency contacts.',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear storage
      final storageService = StorageService();
      await storageService.clearUserId();
      
      // Navigate to app initializer (which will redirect to registration)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AppInitializer(),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
