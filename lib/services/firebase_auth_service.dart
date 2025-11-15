import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      print('📱 Sending OTP to: $phoneNumber');
      
      // Validate phone number format
      if (!phoneNumber.startsWith('+')) {
        return {
          'success': false,
          'message': 'Phone number must start with country code (e.g., +91)',
        };
      }

      // Validate minimum length (country code + at least 10 digits)
      final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length < 10) {
        return {
          'success': false,
          'message': 'Phone number must be at least 10 digits',
        };
      }

      final completer = Completer<Map<String, dynamic>>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        
        // Auto-verification completed (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Auto-verification completed');
          try {
            await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete({
                'success': true,
                'message': 'Phone number verified automatically',
              });
            }
          } catch (e) {
            print('❌ Auto sign-in failed: $e');
            if (!completer.isCompleted) {
              completer.complete({
                'success': false,
                'message': 'Auto-verification failed: ${e.toString()}',
              });
            }
          }
        },
        
        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');
          
          String errorMessage = e.message ?? 'Verification failed';
          
          // Handle specific error codes
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number. Please check the format and try again.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded. Please try again tomorrow.';
          } else if (e.code == 'network-request-failed') {
            errorMessage = 'Network error. Please check your connection.';
          }
          
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'message': errorMessage,
            });
          }
        },
        
        // OTP sent successfully
        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP sent successfully');
          print('📝 Verification ID: ${verificationId.substring(0, 20)}...');
          _verificationId = verificationId;
          _resendToken = resendToken;
          
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP sent successfully. Check your SMS.',
            });
          }
        },
        
        // Auto-retrieval timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        
        forceResendingToken: _resendToken,
      );

      // Wait for one of the callbacks to complete
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return {
            'success': false,
            'message': 'Request timeout. Please check your internet connection and try again.',
          };
        },
      );
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Verify OTP and sign in
  Future<Map<String, dynamic>> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) {
        return {
          'success': false,
          'message': 'Verification ID not found. Please request OTP again.',
        };
      }

      print('🔐 Verifying OTP: $smsCode');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken != null) {
        print('✅ OTP verified successfully');
        return {
          'success': true,
          'firebaseToken': idToken,
          'phoneNumber': userCredential.user?.phoneNumber,
          'uid': userCredential.user?.uid,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get authentication token',
        };
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP. Please check and try again.';
          break;
        case 'session-expired':
          message = 'OTP expired. Please request a new one.';
          break;
        default:
          message = e.message ?? 'Verification failed';
      }
      
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get current Firebase ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      print('❌ Error getting ID token: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _verificationId = null;
      _resendToken = null;
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    return await sendOTP(phoneNumber);
  }
}
