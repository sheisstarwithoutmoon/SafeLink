import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch both sent and received notifications from backend
      final sentResponse = await _apiService.getSentNotifications(limit: 50);
      final receivedResponse = await _apiService.getReceivedNotifications(limit: 50);

      if (sentResponse['success'] == true || receivedResponse['success'] == true) {
        final sentNotifications = (sentResponse['notifications'] as List<dynamic>?) ?? [];
        final receivedNotifications = (receivedResponse['notifications'] as List<dynamic>?) ?? [];
        
        // Convert sent notifications
        final sentList = sentNotifications.map((notification) {
          return {
            'title': 'Alert Sent',
            'body': 'Emergency alert sent to all contacts',
            'userName': notification['user']?['name'] ?? 'You',
            'userPhone': notification['user']?['phoneNumber'] ?? '',
            'latitude': notification['location']?['latitude']?.toString() ?? '0',
            'longitude': notification['location']?['longitude']?.toString() ?? '0',
            'severity': notification['severity'] ?? 'high',
            'timestamp': notification['createdAt'] != null 
                ? DateTime.parse(notification['createdAt']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'time': notification['createdAt'] ?? DateTime.now().toIso8601String(),
            'status': notification['status'] ?? 'sent',
            'type': 'sent',
          };
        }).toList();

        // Convert received notifications
        final receivedList = receivedNotifications.map((notification) {
          return {
            'title': 'Emergency Alert',
            'body': notification['message'] ?? 'Emergency alert from ${notification['user']?['name'] ?? 'Unknown'}',
            'userName': notification['user']?['name'] ?? 'Unknown',
            'userPhone': notification['user']?['phoneNumber'] ?? 'Unknown',
            'latitude': notification['location']?['latitude']?.toString() ?? '0',
            'longitude': notification['location']?['longitude']?.toString() ?? '0',
            'severity': notification['severity'] ?? 'high',
            'timestamp': notification['createdAt'] != null 
                ? DateTime.parse(notification['createdAt']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'time': notification['createdAt'] ?? DateTime.now().toIso8601String(),
            'status': notification['status'] ?? 'delivered',
            'type': 'received',
          };
        }).toList();

        // Combine and sort by timestamp
        final allNotifications = [...sentList, ...receivedList];
        allNotifications.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        
        setState(() {
          _notifications = allNotifications;
          _isLoading = false;
        });
        
        print('Loaded ${sentList.length} sent and ${receivedList.length} received notifications');
      } else {
        // Fallback to local storage
        print('Backend fetch failed, loading from local storage');
        final localNotifications = await _storageService.getNotificationHistory();
        
        setState(() {
          _notifications = localNotifications;
          _isLoading = false;
          if (localNotifications.isEmpty) {
            _errorMessage = 'Failed to load notifications';
          }
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      
      // Fallback to local storage on error
      try {
        final localNotifications = await _storageService.getNotificationHistory();
        setState(() {
          _notifications = localNotifications;
          _isLoading = false;
          if (localNotifications.isEmpty) {
            _errorMessage = 'Could not connect to server';
          }
        });
      } catch (localError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading notifications';
        });
      }
    }
  }

  Future<void> _openMaps(String latitude, String longitude) async {
    try {
      // Try Google Maps app first
      final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to geo URL
      final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // Last fallback to web maps
      final webMapsUrl = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
      await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      // Format as "Nov 15, 2025 3:45 PM"
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = monthNames[dateTime.month - 1];
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$month ${dateTime.day}, ${dateTime.year} $hour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear all',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Are you sure you want to clear all notification history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _storageService.clearNotificationHistory();
                  _loadNotifications();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Emergency alerts will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(context, notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final userName = data['userName'] ?? 'Unknown';
    final userPhone = data['userPhone'] ?? 'Unknown';
    final latitude = data['latitude'] ?? '0';
    final longitude = data['longitude'] ?? '0';
    final severity = data['severity'] ?? 'high';
    final type = data['type'] ?? 'received'; // 'sent' or 'received'
    
    // Color theme based on type
    final bool isSentByUser = type == 'sent';
    final Color iconColor = isSentByUser ? Colors.blue : (severity == 'critical' ? Colors.red : Colors.orange);
    final Color backgroundColor = isSentByUser ? Colors.blue.withOpacity(0.1) : (severity == 'critical' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1));
    final IconData icon = isSentByUser ? Icons.send_rounded : Icons.warning_amber_rounded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSentByUser ? Colors.blue.withOpacity(0.3) : (severity == 'critical' ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showNotificationDetails(context, data);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSentByUser ? 'Alert Sent' : 'Emergency Alert',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isSentByUser ? 'SENT' : 'RECEIVED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSentByUser ? 'To: Emergency Contacts' : 'From: $userName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (!isSentByUser) const SizedBox(height: 2),
                    if (!isSentByUser)
                      Text(
                        userPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, Map<String, dynamic> data) {
    final timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final userName = data['userName'] ?? 'Unknown';
    final userPhone = data['userPhone'] ?? 'Unknown';
    final latitude = data['latitude'] ?? '0';
    final longitude = data['longitude'] ?? '0';
    final severity = data['severity'] ?? 'high';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Emergency Alert Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
                      _buildDetailRow('From:', userName),
                      const SizedBox(height: 12),
                      _buildDetailRow('Phone:', userPhone),
                      const SizedBox(height: 12),
                      _buildDetailRow('Time:', _formatTimestamp(timestamp)),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _openMaps(latitude, longitude);
                        },
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
                              const Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Location:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),
                                  Icon(Icons.open_in_new, color: Colors.blue, size: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lat: $latitude\nLong: $longitude',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to open in Maps',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
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
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
