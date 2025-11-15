import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@saferide.com',
      query: 'subject=Safe Ride Support Request',
    );
    if (!await launchUrl(emailUri)) {
      throw Exception('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mail_rounded, color: Colors.blue),
                  ),
                  title: const Text(
                    'Contact Support',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('support@saferide.com'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _sendEmail().catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open email app'),
                        ),
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.question_answer_rounded, color: Colors.green),
                  ),
                  title: const Text(
                    'FAQ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Frequently asked questions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FAQScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.book_rounded, color: Colors.orange),
                  ),
                  title: const Text(
                    'User Guide',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Learn how to use Safe Ride'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserGuideScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'EMERGENCY',
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
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Services',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In case of a real emergency, always call your local emergency number:\n\n'
                    '🚨 Emergency: 911 (US)\n'
                    '🚨 Emergency: 112 (EU)\n'
                    '🚨 Emergency: 100 (India)',
                    style: TextStyle(
                      fontSize: 13,
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

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            'How does accident detection work?',
            'Safe Ride uses sensors in your helmet to detect sudden impacts and deceleration patterns consistent with accidents. When detected, it automatically alerts your emergency contacts.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'How do I connect my helmet?',
            'Go to Settings → Bluetooth Connection, make sure your helmet is powered on, and select it from the list of available devices.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Can I cancel a false alarm?',
            'Yes! When an accident is detected, you have 15 seconds to cancel the alert before your emergency contacts are notified.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'How many emergency contacts can I add?',
            'You can add up to 5 emergency contacts. We recommend adding at least 2 contacts for redundancy.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'What information is shared during an emergency?',
            'Your name, phone number, current location (GPS coordinates and map link), and the time of the accident are shared with your emergency contacts.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Does the app work without internet?',
            'The app requires internet connection to send emergency notifications. Make sure you have mobile data enabled while riding.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideSection(
            context,
            icon: Icons.person_add_rounded,
            title: 'Getting Started',
            description: '1. Complete registration with your details\n'
                '2. Add at least 2 emergency contacts\n'
                '3. Connect your helmet via Bluetooth\n'
                '4. Enable all permissions for best experience',
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            context,
            icon: Icons.bluetooth_rounded,
            title: 'Connecting Your Helmet',
            description: '1. Turn on your helmet and enable Bluetooth\n'
                '2. Go to Settings → Bluetooth Connection\n'
                '3. Select your helmet from available devices\n'
                '4. Wait for successful connection',
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'Accident Detection',
            description: 'The system monitors your helmet sensors in real-time:\n\n'
                '• Automatic detection of impacts\n'
                '• 15-second countdown to cancel\n'
                '• Automatic notification to contacts\n'
                '• GPS location shared instantly',
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            context,
            icon: Icons.contacts_rounded,
            title: 'Emergency Contacts',
            description: 'Manage your emergency contacts:\n\n'
                '• Add up to 5 contacts\n'
                '• Include name and phone number\n'
                '• Select relationship type\n'
                '• Update or remove anytime',
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            context,
            icon: Icons.battery_charging_full_rounded,
            title: 'Battery Optimization',
            description: 'For best performance:\n\n'
                '• Disable battery optimization for Safe Ride\n'
                '• Keep Bluetooth enabled while riding\n'
                '• Ensure mobile data is active\n'
                '• Keep helmet charged',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
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
                Container(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
