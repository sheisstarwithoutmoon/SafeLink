import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../widgets/contact_card.dart';
import '../widgets/instructions_card.dart';
import '../utils/app_theme.dart';
import '../utils/date_time_utils.dart';

class SMSTestPage extends StatefulWidget {
  const SMSTestPage({Key? key}) : super(key: key);

  @override
  State<SMSTestPage> createState() => _SMSTestPageState();
}

class _SMSTestPageState extends State<SMSTestPage> {
  final TextEditingController _phoneController = TextEditingController();
  final SMSService _smsService = SMSService();
  final StorageService _storageService = StorageService();
  
  String emergencyContact = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    String contact = await _storageService.getEmergencyContact();
    setState(() {
      emergencyContact = contact;
      _phoneController.text = contact;
    });
  }

  Future<void> _saveEmergencyContact() async {
    String contact = _phoneController.text.trim();
    
    if (contact.isEmpty) {
      _showMessage("Please enter a phone number");
      return;
    }

    if (!_smsService.isValidPhoneNumber(contact)) {
      _showMessage("Invalid phone number format! Use +1234567890 or 9876543210");
      return;
    }

    await _storageService.saveEmergencyContact(contact);
    setState(() {
      emergencyContact = contact;
    });
    _showMessage("Contact saved successfully!", isError: false);
  }

  Future<void> _sendTestSMS() async {
    if (emergencyContact.isEmpty) {
      _showMessage("Please set emergency contact first!");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String smsBody = "EMERGENCY ALERT - TEST SMS!\n"
          "This is a test message from Safe Ride app.\n"
          "Time: ${DateTimeUtils.formatDateTime(DateTime.now())}\n\n"
          "If you receive this, SMS is working!";

      bool success = await _smsService.sendEmergencySMS(
        phoneNumber: emergencyContact,
        message: smsBody,
      );

      if (success) {
        _showMessage("SMS sent successfully!", isError: false);
      }
    } catch (e) {
      _showMessage("Failed to send SMS: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Emergency Contact"),
        content: TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: "Phone Number",
            hintText: "+1234567890",
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _phoneController.text = emergencyContact;
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveEmergencyContact();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMS Test"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  Icon(Icons.message, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Test Emergency SMS",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Verify that emergency alerts work correctly",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Phone Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Emergency Contact Number",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        hintText: "+1234567890 or 9876543210",
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveEmergencyContact,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Contact"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Contact Display
            ContactCard(
              contactNumber: emergencyContact,
              onEdit: _showEditDialog,
            ),

            const SizedBox(height: 24),

            // Test SMS Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: emergencyContact.isEmpty || isLoading
                      ? [Colors.grey, Colors.grey.shade400]
                      : [AppColors.success, AppColors.success.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (emergencyContact.isNotEmpty && !isLoading)
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading || emergencyContact.isEmpty 
                    ? null 
                    : _sendTestSMS,
                icon: isLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, size: 24),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    isLoading ? "Sending SMS..." : "Send Test SMS",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            const InstructionsCard(),
          ],
        ),
      ),
    );
  }
}
