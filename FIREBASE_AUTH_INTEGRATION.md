# Firebase Authentication Integration - Safe Ride

## Overview

The app now uses **Firebase Authentication** for secure phone number verification with OTP (One-Time Password) sent via SMS.

## Implementation Summary

### 1. New Files Created

#### `lib/services/firebase_auth_service.dart`
- Handles Firebase phone authentication
- Methods:
  - `sendOTP(phoneNumber)` - Sends OTP to user's phone
  - `verifyOTP(smsCode)` - Verifies the OTP code
  - `getIdToken()` - Gets Firebase ID token for API authentication
  - `signOut()` - Signs out user
  - `resendOTP()` - Resends OTP if expired

#### `lib/screens/otp_verification_screen.dart`
- Beautiful UI for entering 6-digit OTP
- Auto-focuses next field when digit entered
- Auto-verifies when all 6 digits entered
- Resend OTP functionality with 60-second countdown
- Real-time error handling

### 2. Updated Files

#### `lib/screens/registration_screen.dart`
**Changes:**
- Removed direct registration
- Changed "Create Account" button to "Send OTP"
- Updated flow: Enter details → Send OTP → Navigate to OTP screen
- Default country code changed to +91 (India)
- Removed old test connection button

#### `lib/services/api_service.dart`
**Changes:**
- Added `firebaseToken` parameter to `registerUser()` method
- Updated `_getHeaders()` to support Authorization Bearer token
- Maintains backward compatibility with old phone-based registration
- Automatically saves phone number from Firebase user data

### 3. Updated Dependencies

All required packages already installed in `pubspec.yaml`:
```yaml
firebase_core: ^3.15.0
firebase_auth: ^5.3.3
```

## User Flow

### Old Flow (Legacy - Still Supported)
```
Registration Screen
  ↓ (Enter name + phone)
  ↓ (Click "Create Account")
Backend Registration
  ↓
Home Screen
```

### New Flow (Firebase Auth)
```
Registration Screen
  ↓ (Enter name + phone)
  ↓ (Click "Send OTP")
OTP Verification Screen
  ↓ (Enter 6-digit OTP)
  ↓ (Verify with Firebase)
  ↓ (Get Firebase token)
Backend Registration (with token)
  ↓
Home Screen
```

## Backend Integration

### API Endpoint: `/api/users/register`

**New Request (with Firebase):**
```json
{
  "firebaseToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
  "name": "John Doe",
  "fcmToken": "device_fcm_token"
}
```

**Old Request (Legacy - still works):**
```json
{
  "phoneNumber": "+916261795658",
  "name": "John Doe",
  "fcmToken": "device_fcm_token"
}
```

**Response (Same for both):**
```json
{
  "success": true,
  "message": "Authenticated with Firebase",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "phoneNumber": "+916261795658",
    "name": "John Doe",
    "emergencyContacts": [],
    "settings": {...}
  }
}
```

## Benefits

✅ **FREE** - Firebase provides generous free tier for phone auth
✅ **Secure** - Industry-standard authentication with Google's infrastructure
✅ **OTP via SMS** - Automatic SMS sending by Firebase (no Twilio needed)
✅ **Rate Limiting** - Built-in by Firebase to prevent abuse
✅ **No Backend Changes** - Backend already supports Firebase tokens
✅ **Backward Compatible** - Old registration method still works
✅ **Better UX** - Professional OTP verification flow

## Testing

1. Run the app: `flutter run`
2. Navigate to Registration Screen
3. Enter your name and phone number (must be in E.164 format)
4. Click "Send OTP"
5. Check your phone for SMS with 6-digit code
6. Enter the OTP on verification screen
7. Code is auto-verified when complete
8. You'll be registered and navigated to Home Screen

## Firebase Console

Already configured in Firebase project: `alpha-flutter-health`

**Phone Authentication Settings:**
- Provider: Enabled
- Test phone numbers: Can be added in Firebase Console for testing
- SMS quota: 10,000 free verifications/month

## Important Notes

1. **Phone Format**: Must be in E.164 format (e.g., +916261795658)
2. **Country Code**: Default is +91 (India), can be changed in dropdown
3. **OTP Expiry**: OTP expires in 60 seconds
4. **Resend Limit**: Can resend OTP after 60-second countdown
5. **Auto-verification**: Android may auto-verify without user entering code
6. **Testing**: For testing, add test phone numbers in Firebase Console

## Code Examples

### Sending OTP
```dart
final firebaseAuth = FirebaseAuthService();
final result = await firebaseAuth.sendOTP('+916261795658');

if (result['success'] == true) {
  // Navigate to OTP screen
}
```

### Verifying OTP
```dart
final result = await firebaseAuth.verifyOTP('123456');

if (result['success'] == true) {
  final firebaseToken = result['firebaseToken'];
  
  // Register with backend
  final response = await apiService.registerUser(
    firebaseToken: firebaseToken,
    name: 'John Doe',
  );
}
```

## Migration Strategy

1. **Phase 1** (Current): Both methods work (Firebase + Legacy)
2. **Phase 2**: All new users use Firebase Auth
3. **Phase 3**: Existing users gradually migrate to Firebase
4. **Phase 4**: (Optional) Remove legacy method

## Troubleshooting

**Issue**: OTP not received
- Check phone number format (must include country code)
- Verify phone number is not blocked in Firebase Console
- Check SMS quota in Firebase Console

**Issue**: "Invalid verification code"
- OTP may have expired (60 seconds)
- Check if correct 6-digit code entered
- Try resending OTP

**Issue**: Firebase initialization error
- Verify `firebase_options.dart` exists
- Check Firebase is initialized in `main.dart`
- Run `flutterfire configure` if needed

## Security

- Firebase tokens are short-lived (1 hour default)
- Tokens are verified server-side by Firebase Admin SDK
- Phone numbers are verified via SMS OTP
- Rate limiting prevents abuse
- All communication over HTTPS

## Next Steps

1. Test OTP flow with real phone numbers
2. Add test phone numbers in Firebase Console for development
3. Monitor Firebase Authentication usage in console
4. Consider adding reCAPTCHA for web (if needed)
5. Implement token refresh logic for long sessions

---

**Status**: ✅ Fully Implemented & Ready for Testing
**Backend**: Already configured and deployed
**Frontend**: All screens and services integrated
**Documentation**: Complete
