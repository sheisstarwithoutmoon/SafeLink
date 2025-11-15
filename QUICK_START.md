# Quick Start Guide - Safe Ride Backend Integration

## Problem Fixed
Your app was still using the **OLD Firebase Functions SMS service** which was failing. We've now switched to the **NEW custom backend** with FREE push notifications!

## What Changed

### Before (Old System - Firebase Functions):
- Used expensive Twilio SMS ($$$)
- Firebase Functions errors
- No real-time updates
- Limited to SMS only

### After (New System - Custom Backend):
- FREE push notifications via FCM
- Real-time location updates via Socket.IO
- 15-second countdown to cancel
- Works even when app is closed
- No costs for alerts

## Step-by-Step Setup

### 1. Start MongoDB (If Local)

**Option A: Windows Service**
```powershell
# Start MongoDB service
net start MongoDB
```

**Option B: Manual Start**
```powershell
# Navigate to MongoDB bin folder
cd "C:\Program Files\MongoDB\Server\7.0\bin"
# Start MongoDB
.\mongod.exe --dbpath "C:\data\db"
```

**Option C: Use MongoDB Atlas (Cloud)**
- Sign up at https://www.mongodb.com/cloud/atlas
- Create free cluster
- Get connection string
- Update `backend/.env` with: `MONGODB_URI=mongodb+srv://...`

### 2. Setup Backend

```powershell
# Navigate to backend folder
cd c:\flutter_projects\safe_ride\backend

# Install dependencies (if not done)
npm install

# Create .env file (if not exists)
# Copy this content to backend/.env:
```

**backend/.env** (create this file):
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/safe_ride
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
NODE_ENV=development
```

### 3. Get Firebase Service Account

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **alpha-flutter-health**
3. Click (Settings) → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Download the JSON file
7. Rename it to: `firebase-service-account.json`
8. Place it in: `c:\flutter_projects\safe_ride\backend\`

### 4. Start Backend Server

```powershell
# From backend folder
cd c:\flutter_projects\safe_ride\backend

# Start server
npm start

# OR for development with auto-reload
npm run dev
```

**Expected Output:**
```
Server running on port 5000
MongoDB connected successfully
Firebase Admin initialized
Socket.IO initialized
```

### 5. Run Flutter App

```powershell
# From project root
cd c:\flutter_projects\safe_ride

# Run on connected device
flutter run
```

## Testing the New System

### Test Flow:

1. **Register User**
   - Enter your name
   - Enter phone: `+916261795658` or just `6261795658`
   - Click "Register"
   - Should show "Registration successful!"

2. **Add Emergency Contact**
   - Enter contact name (e.g., "Mom", "Wife")
   - Enter phone: `+919876543210` or just `9876543210`
   - Click "Add Contact"
   - Contact appears in list below

3. **Create Test Alert**
   - Click "CREATE TEST ALERT" button
   - Countdown dialog appears (15 seconds)
   - Option 1: Click "Cancel Alert" to test cancellation
   - Option 2: Wait 15 seconds for alert to send

4. **Verify Alert Sent**
   - Emergency contacts receive **push notification**
   - Socket.IO shows real-time updates
   - Check backend console for logs

## Troubleshooting

### Backend Won't Start

**Error: MongoDB connection failed**
```
Solution:
1. Check if MongoDB is running: mongod --version
2. Start MongoDB service: net start MongoDB
3. Or use MongoDB Atlas (cloud)
```

**Error: Cannot find module**
```powershell
Solution:
cd backend
npm install
```

**Error: Firebase service account not found**
```
Solution:
1. Download from Firebase Console
2. Save as: backend/firebase-service-account.json
3. Check path in .env file
```

### Flutter App Errors

**Error: Socket not connecting**
```
Solution:
1. Check backend is running on http://localhost:5000
2. Check lib/config/api_config.dart has correct URL
3. Restart app: flutter run
```

**Error: FCM token null**
```
Solution:
1. Check google-services.json exists in android/app/
2. Rebuild app: flutter clean && flutter run
3. Grant notification permissions on device
```

**Error: Location permission denied**
```
Solution:
1. Go to device Settings → Apps → Safe Ride → Permissions
2. Enable Location permission
3. Try creating alert again
```

### No Push Notifications

**Contact not receiving notifications**
```
Possible causes:
1. Contact doesn't have app installed ✓ Expected!
2. Contact's app not registered ✓ They need to register too
3. FCM token not saved ✓ Check backend logs
4. Notification permissions denied ✓ Check device settings
```

**Solution:**
For testing, install app on 2 devices:
- Device 1: Your phone (driver)
- Device 2: Contact's phone (emergency contact)
- Register both users with different phone numbers
- Add Device 1's number to Device 2's emergency contacts
- Create alert on Device 1
- Device 2 receives push notification!

## Backend API Status Check

Test if backend is running:

```powershell
# Open browser or use curl
curl http://localhost:5000/api/users/profile

# Expected: 400 error (because no user-id header)
# But proves server is responding!
```

## Monitoring Backend

**View Logs:**
```powershell
# Backend console shows:
- User registrations
- Alert creations
- FCM notifications sent
- Socket.IO connections
- Errors (if any)
```

**Check MongoDB Data:**
```powershell
# Connect to MongoDB
mongosh

# Switch to database
use safe_ride

# View users
db.users.find().pretty()

# View alerts
db.accidentalerts.find().pretty()

# Count documents
db.users.countDocuments()
db.accidentalerts.countDocuments()
```

## Understanding the Flow

```
1. Driver's Phone (Accident Detected)
   ↓
2. Flutter App → ApiService.createAlert()
   ↓
3. HTTP POST to Backend: http://localhost:5000/api/alerts
   ↓
4. Backend saves to MongoDB
   ↓
5. Backend starts 15-second countdown
   ↓
6. Socket.IO emits real-time countdown updates
   ↓
7. Driver can cancel via Socket.IO
   ↓
8. After 15 seconds (if not cancelled):
   ↓
9. Backend sends FCM push notifications
   ↓
10. Emergency contacts' phones receive notification
    ↓
11. Contacts open app → See driver's location
    ↓
12. Real-time location updates via Socket.IO
```

## Files Changed

### ✅ Created New Files:
- `lib/services/api_service.dart` - HTTP API client
- `lib/services/socket_service.dart` - Socket.IO client
- `lib/services/fcm_service.dart` - Push notifications
- `lib/screens/emergency_test_page.dart` - New test UI
- `backend/` - Complete Node.js backend (9 files)

### ✅ Updated Files:
- `lib/main.dart` - Now uses EmergencyTestPage instead of SMSTestPage
- `lib/services/storage_service.dart` - Added user ID & FCM token storage
- `pubspec.yaml` - Added new dependencies

### ❌ Deprecated (Not Used):
- `lib/services/sms_service.dart` - Old Firebase Functions SMS
- `lib/screens/sms_test_page.dart` - Old SMS test UI

## Production Deployment

When ready for production:

1. **Deploy Backend:**
   - Use Heroku, Railway, DigitalOcean, or AWS
   - Set environment variables
   - Update MongoDB URI to Atlas

2. **Update Flutter App:**
   - Edit `lib/config/api_config.dart`
   - Change `baseUrl` to production URL
   - Example: `https://saferide-backend.herokuapp.com`

3. **Build APK:**
   ```powershell
   flutter build apk --release
   ```

## Cost Comparison

| Feature | Old System (SMS) | New System (FCM) |
|---------|------------------|------------------|
| Alert Cost | $0.05 per SMS | $0.00 (FREE) |
| 100 alerts | $5.00 | $0.00 |
| 1000 alerts | $50.00 | $0.00 |
| Real-time updates | ❌ No | ✅ Yes |
| Works offline | ❌ No | ✅ Yes (queued) |
| Delivery confirmation | ❌ Limited | ✅ Full tracking |

## Next Steps

1. ✅ Start backend server
2. ✅ Run Flutter app
3. ✅ Register as user
4. ✅ Add emergency contact
5. ✅ Test alert creation
6. ⏳ Integrate with Bluetooth HC-05
7. ⏳ Test with real accident detection
8. ⏳ Deploy to production

## Support

**Need Help?**
1. Check backend console logs
2. Check Flutter debug console
3. Verify MongoDB is running
4. Test API endpoints with Postman
5. Review BACKEND_INTEGRATION_GUIDE.md

**Common Questions:**

Q: Why do I need 2 phones to test?
A: Push notifications need a recipient. Install app on both devices to simulate driver + emergency contact.

Q: Can I use SMS as fallback?
A: Yes! Backend has Twilio integration. Set `sendSMSFallback: true` in user settings.

Q: How do I know if alert was received?
A: Check backend logs for "FCM notification sent" messages.

Q: App crashes on startup?
A: Check Firebase is initialized. Verify google-services.json exists.

---

## Summary

✅ **Old system removed:** No more Firebase Functions errors
✅ **New backend active:** FREE push notifications
✅ **Real-time updates:** Socket.IO for live location
✅ **Cost savings:** $0 vs $50+ per 1000 alerts
✅ **Better UX:** 15-second countdown, cancel option
✅ **Production ready:** Scalable architecture

**Start the backend and test now! 🚀**
