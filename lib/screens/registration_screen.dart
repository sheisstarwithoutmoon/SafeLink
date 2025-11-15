import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/fcm_service.dart';
import '../models/user.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final FcmService _fcmService = FcmService();
  
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String _selectedCountryCode = '+1';

  final List<String> _countryCodes = [
    '+1',   // USA/Canada
    '+44',  // UK
    '+91',  // India
    '+86',  // China
    '+81',  // Japan
    '+49',  // Germany
    '+33',  // France
    '+39',  // Italy
    '+34',  // Spain
    '+61',  // Australia
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                
                // Header
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your emergency profile',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // Info about first connection
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'First connection may take up to 60 seconds',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Name field
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Phone number field with country code
                Text(
                  'Phone Number',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Country code dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderGray),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        underline: const SizedBox(),
                        items: _countryCodes.map((code) {
                          return DropdownMenuItem(
                            value: code,
                            child: Text(code),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCountryCode = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone number field
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '(555) 123-4567',
                          hintStyle: TextStyle(color: AppTheme.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.borderGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.borderGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryAccent, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.emergencyRed),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Terms checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryAccent,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Register button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _agreedToTerms && !_isLoading ? _handleRegister : null,
                  type: CustomButtonType.primary,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12),

                // Test connection button (for debugging)
                TextButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test Server Connection'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // Already have account
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Navigate to login if it exists
                    },
                    child: Text(
                      'Already have an account? Sign in',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show initial message about potential cold start
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to server... First attempt may take 30-60 seconds'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final fullPhone = '$_selectedCountryCode${_phoneController.text}';
      print('📱 Registering user with phone: $fullPhone');
      
      final fcmToken = await _fcmService.getToken();
      print('🔔 FCM Token: ${fcmToken?.substring(0, 20)}...');

      print('🌐 Calling API registerUser...');
      final response = await _apiService.registerUser(
        name: _nameController.text,
        phone: fullPhone,
        fcmToken: fcmToken ?? '',
      );

      print('📦 API Response: $response');

      if (response['success'] == true) {
        print('✅ Registration successful!');
        final user = User.fromJson(response['user']);
        await _storageService.saveUserId(user.id);
        
        // Save phone number for future FCM token updates
        await _storageService.savePhoneNumber(fullPhone);
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Small delay to show success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
      } else {
        if (!mounted) return;
        
        print('❌ Registration failed: ${response['message']}');
        
        // Check if it's a timeout and offer to retry
        final message = response['message'] ?? 'Registration failed';
        final isTimeout = message.contains('timeout') || message.contains('Timeout');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: isTimeout ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _handleRegister,
            ) : null,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      print('❌ Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waking up server... This may take 30-60 seconds on first try'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      print('🌐 Testing connection to: https://saferide-backend-04w2.onrender.com');
      final response = await http.get(
        Uri.parse('https://saferide-backend-04w2.onrender.com'),
      ).timeout(const Duration(seconds: 90));

      print('📊 Server response: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Server is online and ready!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Server returned: ${response.statusCode}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Server unavailable: ${e.toString().contains('TimeoutException') ? 'Timeout - server may be starting up' : e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
