# 🔧 SMS Debugging Guide

Your Firebase Functions are now properly deployed! Here's how to test and debug the SMS functionality:

## ✅ Current Status
- ✅ Firebase Functions deployed successfully
- ✅ `sendEmergencySMS` is now callable (not https)
- ✅ Twilio secrets configured
- ✅ Flutter app updated with cloud_functions

## 🧪 Testing Steps

### 1. Test in Flutter App
1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Set emergency contact:**
   - Open app → Settings (⚙️)
   - Enter your phone number (e.g., +1234567890)
   - Save settings

3. **Test SMS:**
   - Tap "Test Emergency SMS" button
   - Check your phone for SMS

### 2. Check Function Logs
```bash
firebase functions:log --only sendEmergencySMS
```

### 3. Check Firestore
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to Firestore Database
3. Look for `emergency_alerts` collection
4. Check for new documents when you test

### 4. Check Twilio Console
1. Go to [Twilio Console](https://console.twilio.com/)
2. Navigate to Monitor → Logs → Messages
3. Look for sent messages

## 🚨 Common Issues & Solutions

### Issue 1: "Function not found"
**Solution:**
```bash
firebase deploy --only functions
```

### Issue 2: "SMS service not configured properly"
**Check Twilio secrets:**
```bash
firebase functions:secrets:access TWILIO_ACCOUNT_SID
firebase functions:secrets:access TWILIO_AUTH_TOKEN
firebase functions:secrets:access TWILIO_PHONE_NUMBER
```

### Issue 3: "Failed to send SMS"
**Check Twilio account:**
- Verify account balance
- Check phone number format
- Ensure Twilio phone number is verified

### Issue 4: App crashes on SMS test
**Check Flutter logs:**
```bash
flutter logs
```

## 🔍 Debugging Commands

### Check Function Status
```bash
firebase functions:list
```

### View Function Logs
```bash
firebase functions:log
```

### Test Function Directly
```bash
firebase functions:shell
# Then in the shell:
sendEmergencySMS({phoneNumber: '+1234567890', message: 'Test message'})
```

### Check Firestore
```bash
firebase firestore:get emergency_alerts
```

## 📱 Flutter App Testing

### Test Scenarios:

1. **Basic SMS Test:**
   - Set emergency contact
   - Tap "Test Emergency SMS"
   - Should receive SMS

2. **Location Test:**
   - Enable location permissions
   - Test SMS with location
   - SMS should include Google Maps link

3. **Fallback Test:**
   - Disconnect internet
   - Try SMS test
   - Should fall back to URL launcher

## 🎯 Expected Behavior

### Successful SMS:
- ✅ App shows "Sending emergency alert..."
- ✅ App shows "✅ Emergency alert sent successfully!"
- ✅ Phone receives SMS with:
  - Accident alert message
  - Location (Google Maps link)
  - Impact intensity
  - Timestamp

### Failed SMS:
- ❌ App shows "Failed to send SMS: [error]"
- ❌ Falls back to URL launcher
- ❌ Logs error to Firestore

## 📊 Monitoring

### Firebase Console:
1. **Functions** → Check deployment status
2. **Firestore** → `emergency_alerts` collection
3. **Functions** → Logs for detailed errors

### Twilio Console:
1. **Monitor** → Logs → Messages
2. **Phone Numbers** → Verify your Twilio number
3. **Account** → Check balance

## 🚀 Next Steps

1. **Test the app** with the steps above
2. **Check logs** if SMS doesn't work
3. **Verify Twilio setup** if errors occur
4. **Report specific errors** for further debugging

## 📞 Support

If you encounter specific errors, please share:
1. The exact error message
2. Flutter logs output
3. Firebase function logs
4. Your phone number format

The SMS functionality should now work reliably with Twilio!
