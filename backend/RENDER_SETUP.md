# Render Deployment Setup Guide

## Firebase Configuration for Render

To enable FCM push notifications on Render, you need to add your Firebase service account credentials as an environment variable.

### Step 1: Get Firebase Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **alpha-flutter-health**
3. Click the gear icon (⚙️) → **Project Settings**
4. Navigate to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Download the JSON file (e.g., `alpha-flutter-health-firebase-adminsdk-xxxxx.json`)

### Step 2: Add to Render Environment Variables

1. Go to your Render Dashboard: [https://dashboard.render.com](https://dashboard.render.com)
2. Select your **Safe Ride Backend** service
3. Go to **Environment** tab
4. Add the following environment variable:

**Key:** `FIREBASE_SERVICE_ACCOUNT`

**Value:** Copy the **entire contents** of the JSON file you downloaded. It should look like:

```json
{"type":"service_account","project_id":"alpha-flutter-health","private_key_id":"abc123...","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvgIBA...","client_email":"firebase-adminsdk-xxxxx@alpha-flutter-health.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40alpha-flutter-health.iam.gserviceaccount.com"}
```

**IMPORTANT:** 
- Copy the ENTIRE JSON object as a single line
- Do NOT add line breaks or formatting
- Include the curly braces `{` and `}`

5. Click **Save Changes**
6. Render will automatically redeploy your service

### Step 3: Verify Setup

After deployment completes, check the logs:

1. Go to **Logs** tab in Render dashboard
2. Look for: `✅ Firebase Admin SDK initialized`
3. You should see: `📱 Project ID: alpha-flutter-health`

If you see errors, check that:
- The JSON is valid (no syntax errors)
- The entire JSON was copied (including all keys)
- No extra spaces or line breaks were added

### Step 4: Test Notifications

1. Trigger an accident detection in the app
2. Check Render logs for: `✅ FCM notification sent`
3. Emergency contact should receive push notification

### Environment Variables Checklist

Make sure these are all set in Render:

- ✅ `MONGODB_URI` - Your MongoDB Atlas connection string
- ✅ `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON (added above)
- ✅ `FIREBASE_PROJECT_ID` - Your Firebase project ID (e.g., `alpha-flutter-health`)
- ✅ `JWT_SECRET` - Random secret key for JWT tokens
- ✅ `CORS_ORIGIN` - Set to `*` or your app's domain
- ⚠️ `TWILIO_ACCOUNT_SID` - (Optional) Only if using SMS fallback
- ⚠️ `TWILIO_AUTH_TOKEN` - (Optional) Only if using SMS fallback
- ⚠️ `TWILIO_PHONE_NUMBER` - (Optional) Only if using SMS fallback

### Troubleshooting

**Error: "Cannot read properties of undefined (reading 'then')"**
- Firebase credentials not configured
- Add `FIREBASE_SERVICE_ACCOUNT` environment variable as shown above

**Error: "Invalid service account"**
- JSON is malformed or incomplete
- Re-copy the entire JSON from the downloaded file
- Ensure no line breaks or extra spaces

**Error: "Project ID mismatch"**
- Make sure `FIREBASE_PROJECT_ID` matches your Firebase project
- Check that the service account is from the correct project

**Notifications not received:**
- Check that emergency contact has the app installed
- Verify they registered with the same phone number
- Check their FCM token is saved in database
- Ensure they allowed notification permissions

### Support

For issues, check:
- Render logs: Look for Firebase initialization messages
- MongoDB: Verify user has `fcmToken` field populated
- Firebase Console: Check project settings and service account permissions
