import 'package:cloud_functions/cloud_functions.dart';

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  Future<bool> sendEmergencySMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Add country code if missing (assuming India +91, adjust as needed)
      if (!cleanedNumber.startsWith('+')) {
        // If number starts with 91, add +
        if (cleanedNumber.startsWith('91') && cleanedNumber.length > 10) {
          cleanedNumber = '+$cleanedNumber';
        } 
        // If 10 digit number, assume India and add +91
        else if (cleanedNumber.length == 10) {
          cleanedNumber = '+91$cleanedNumber';
        }
        // Otherwise, show error
        else {
          throw Exception('Please enter phone number with country code (e.g., +91XXXXXXXXXX)');
        }
      }
      
      // Validate phone number
      if (!RegExp(r'^\+[0-9]{10,15}$').hasMatch(cleanedNumber)) {
        throw Exception('Invalid phone number format. Use: +91XXXXXXXXXX');
      }

      print('=== SENDING SMS ===');
      print('Phone Number: $cleanedNumber');
      print('Message: $message');

      // Call Firebase function
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'sendEmergencySMS',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );
      
      Map<String, dynamic> requestData = {
        'phoneNumber': cleanedNumber,
        'message': message,
        'timestamp': _formatDateTime(DateTime.now()),
      };

      print('Calling Firebase function: sendEmergencySMS');
      print('Request data: $requestData');
      final result = await callable.call(requestData);

      print('Firebase Result: ${result.data}');

      if (result.data != null && result.data['success'] == true) {
        print("✓ SMS sent: ${result.data['messageId']}");
        return true;
      } else {
        throw Exception(result.data?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      print("SMS Error: $e");
      rethrow;
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  bool isValidPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(cleaned);
  }
}
