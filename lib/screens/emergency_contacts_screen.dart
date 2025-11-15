import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../models/user.dart';
import '../models/emergency_contact.dart';
import '../services/api_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final User user;

  const EmergencyContactsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final ApiService _apiService = ApiService();
  late List<EmergencyContact> _contacts;
  bool _isLoading = false;
  
  final List<String> _countryCodes = [
    '+1',   // USA/Canada
    '+44',  // UK
    '+91',  // India
    '+61',  // Australia
    '+81',  // Japan
    '+86',  // China
    '+33',  // France
    '+49',  // Germany
    '+39',  // Italy
    '+34',  // Spain
  ];

  @override
  void initState() {
    super.initState();
    _contacts = List.from(widget.user.emergencyContacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: AppTheme.primaryAccent,
        elevation: 0,
      ),
      body: _contacts.isEmpty ? _buildEmptyState() : _buildContactsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.contacts_outlined,
                size: 64,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Emergency Contacts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Add contacts who will be notified in case of an emergency',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Add Contact',
              onPressed: _showAddContactDialog,
              type: CustomButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              color: AppTheme.softGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              size: isSmallScreen ? 24 : 28,
              color: AppTheme.primaryAccent,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: isSmallScreen ? 14 : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  contact.phone.isNotEmpty ? contact.phone : 'No phone number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
                if (contact.relationship.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    contact.relationship,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.emergencyRed,
              size: isSmallScreen ? 20 : 24,
            ),
            onPressed: () => _deleteContact(contact),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    bool isPrimary = _contacts.isEmpty;
    String selectedCountryCode = '+91'; // Default to India

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isSmallScreen = MediaQuery.of(dialogContext).size.width < 360;
        
        return AlertDialog(
          title: Text(
            'Add Emergency Contact',
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 20,
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'John Doe',
                      labelStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Phone Number',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Country code dropdown
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderGray),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCountryCode,
                          underline: const SizedBox(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.black,
                          ),
                          items: _countryCodes.map((code) {
                            return DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedCountryCode = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Phone number field
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '9876543210',
                            hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: relationshipController,
                    decoration: InputDecoration(
                      labelText: 'Relationship (optional)',
                      hintText: 'Family, Friend, etc.',
                      labelStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(
                      'Primary Contact',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    ),
                    value: isPrimary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setDialogState(() {
                        isPrimary = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryAccent,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  final fullPhone = '$selectedCountryCode${phoneController.text}';
                  _addContact(
                    nameController.text,
                    fullPhone,
                    relationshipController.text,
                    isPrimary,
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addContact(String name, String phone, String relationship, bool isPrimary) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.addEmergencyContact(
        userId: widget.user.id,
        name: name,
        phone: phone,
        relationship: relationship,
        isPrimary: isPrimary,
      );

      if (response['success']) {
        final newContact = EmergencyContact.fromJson(response['contact']);
        setState(() {
          if (isPrimary) {
            for (var contact in _contacts) {
              contact.isPrimary = false;
            }
          }
          _contacts.add(newContact);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully'),
            backgroundColor: Colors.green,
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
      });
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.emergencyRed),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.deleteEmergencyContact(
        userId: widget.user.id,
        contactId: contact.id,
      );

      if (response['success']) {
        setState(() {
          _contacts.removeWhere((c) => c.id == contact.id);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact deleted'),
            backgroundColor: Colors.green,
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
      });
    }
  }
}
