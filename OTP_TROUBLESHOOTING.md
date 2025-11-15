# OTP Troubleshooting Guide

## Common Issues & Solutions

### 1. OTP Not Received

**Possible Causes:**
- Incorrect phone number format
- Country restrictions
- SMS delays
- Network issues
- Firebase quota exceeded

**Solutions:**

#### Check Phone Number Format
✅ **Correct:** +916261795658 (country code + number)
❌ **Incorrect:** 6261795658 (missing country code)
❌ **Incorrect:** 916261795658 (missing + symbol)

```dart
// Phone should be in E.164 format
final phoneNumber = '+91' + '6261795658'; // India
final phoneNumber = '+1' + '5551234567';  // USA
```

#### Verify Country Code
Make sure you select the correct country code from dropdown:
- +91 (India) - Default
- +1 (USA/Canada)
- +44 (UK)
- etc.

#### Wait Longer
- SMS can take up to **2 minutes** to arrive
- Don't request multiple OTPs rapidly
- Check if SMS arrived in spam/promotions folder

### 2. Invalid Verification Code

**Causes:**
- OTP expired (60 seconds)
- Typo in entering code
- Using old OTP

**Solutions:**
- Request new OTP using "Resend" button
- Wait for 60-second countdown
- Enter OTP carefully (6 digits)

### 3. Firebase Errors

#### quota-exceeded
**Error:** "SMS quota exceeded"
**Cause:** Daily SMS limit reached in Firebase
**Solution:** 
- Wait 24 hours
- Contact admin to increase quota
- Use test phone numbers (see below)

#### invalid-phone-number
**Error:** "Invalid phone number"
**Solution:**
- Use E.164 format (+CountryCode + Number)
- Remove spaces, dashes, parentheses
- Example: +916261795658 ✅ NOT +91 626 179 5658 ❌

#### too-many-requests
**Error:** "Too many requests"
**Solution:**
- Wait 5-10 minutes
- Don't spam "Send OTP" button
- Clear app data and restart

### 4. Testing Without Real Phone

#### Option 1: Firebase Test Phone Numbers

Add test phone numbers in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: `alpha-flutter-health`
3. Authentication → Sign-in method → Phone
4. Scroll to "Phone numbers for testing"
5. Add test number with fixed OTP:
   - Phone: +911234567890
   - OTP: 123456

**Usage:**
```dart
// When using test number, it will auto-accept OTP 123456
final result = await sendOTP('+911234567890');
```

#### Option 2: Android Emulator Auto-verify

On Android emulators, Firebase may auto-verify without SMS:
- Enable Google Play Services
- Use emulator with Google APIs
- Firebase auto-detects emulator and skips SMS

### 5. Country-Specific Issues

#### India (+91)
- Generally works well
- Some carriers may block automated SMS
- Try different phone number if issues persist

#### USA/Canada (+1)
- May require reCAPTCHA verification on web
- Works fine on mobile apps
- AT&T, Verizon, T-Mobile supported

#### UK (+44)
- Usually works fine
- Some virtual numbers may not receive SMS

#### Other Countries
Check Firebase documentation for country support:
https://firebase.google.com/docs/auth/phone-auth

### 6. Network & Permissions

#### Check Permissions
```xml
<!-- Android Manifest -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
```

#### Network Connection
- Ensure stable internet (WiFi or Mobile Data)
- Try switching between WiFi and mobile data
- Disable VPN if enabled

### 7. Debugging Steps

#### Enable Detailed Logging
Check console logs for errors:

```dart
// Look for these logs:
📱 Sending OTP to: +916261795658
✅ OTP sent successfully
📝 Verification ID: AMhfh...
❌ Verification failed: quota-exceeded
```

#### Common Log Messages

**Success:**
```
📱 Sending OTP to: +916261795658
✅ OTP sent successfully
📝 Verification ID: AMhfh7V8...
```

**Failure:**
```
❌ Verification failed: invalid-phone-number
Error: The format of the phone number provided is incorrect.
```

### 8. Alternative Solutions

#### If OTP Continues to Fail

**Option A: Use Legacy Registration (Temporary)**
Comment out Firebase Auth and use direct registration:
```dart
// In registration_screen.dart
// Temporarily bypass OTP for testing
final response = await _apiService.registerUser(
  phoneNumber: fullPhone,
  name: name,
);
```

**Option B: Contact Support**
- Email: support@saferide.com
- Provide: Phone number, country, error message
- We can manually verify your account

**Option C: Try Different Number**
- Use different phone number
- Try number from different carrier
- Use Google Voice number (USA)

### 9. Firebase Console Checks

#### Verify Configuration

1. **Authentication Enabled**
   - Console → Authentication → Sign-in method
   - Phone provider should be **Enabled**

2. **App Configuration**
   - Android: SHA-256 fingerprint added
   - iOS: APNs certificates configured

3. **Quota Status**
   - Check daily SMS quota
   - Free tier: 10,000 verifications/month
   - Paid: Higher limits

4. **App Verification**
   - reCAPTCHA configured (web)
   - SafetyNet enabled (Android)

### 10. Quick Checklist

Before requesting OTP, verify:

- [ ] Phone number includes country code (+91, +1, etc.)
- [ ] Phone number is 10+ digits
- [ ] Country code selected in dropdown matches number
- [ ] Internet connection is stable
- [ ] App has SMS permissions
- [ ] Not requesting OTP too frequently
- [ ] Waiting at least 60 seconds for SMS
- [ ] Checking spam/promotions folder

### 11. Error Code Reference

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `invalid-phone-number` | Wrong format | Use E.164 format (+CountryCode + Number) |
| `quota-exceeded` | Daily limit reached | Wait 24 hours or use test numbers |
| `too-many-requests` | Rate limited | Wait 5-10 minutes |
| `session-expired` | OTP expired | Request new OTP |
| `invalid-verification-code` | Wrong OTP | Check SMS and re-enter |
| `missing-phone-number` | No number provided | Enter phone number |

### 12. Testing Recommendations

#### For Development
1. Use Firebase test phone numbers (free, instant)
2. Use Android emulator (auto-verify)
3. Add multiple test numbers for different countries

#### For Production
1. Test with real phone numbers
2. Test multiple carriers
3. Test in different countries
4. Monitor Firebase quota usage

### 13. Support Contacts

**Firebase Support:**
- https://firebase.google.com/support
- Stack Overflow: firebase-authentication tag

**App Support:**
- Email: support@saferide.com
- GitHub Issues: [SafeLink Repository]

### 14. Known Limitations

#### Firebase Free Tier
- 10,000 phone verifications/month
- Some countries have restrictions
- May require reCAPTCHA on web

#### SMS Delivery
- SMS can take up to 2 minutes
- Some carriers block automated SMS
- Virtual numbers may not work

#### App Store Requirements
- iOS requires APNs setup
- Android requires SHA-256 fingerprint
- Web requires reCAPTCHA v3

---

## Still Having Issues?

If none of these solutions work:

1. **Check Firebase Console** for errors and quota
2. **Try test phone number** from Firebase Console
3. **Use different phone** or carrier
4. **Contact support** with error details
5. **Use legacy registration** as temporary workaround

Remember: Firebase Phone Auth is FREE and works in 200+ countries! Most issues are related to configuration or phone number format.

---

**Last Updated:** November 15, 2025
**Version:** 1.0.0
