# SMS Setup Guide for Safe Ride App

This guide will help you set up reliable SMS sending using Firebase Functions and Twilio.

## Prerequisites

1. Firebase project with Functions enabled
2. Twilio account (free trial available)
3. Node.js installed on your development machine

## Step 1: Set up Twilio Account

1. Go to [Twilio Console](https://console.twilio.com/)
2. Sign up for a free account (includes $15 credit)
3. Get a phone number:
   - Go to Phone Numbers → Manage → Buy a number
   - Choose a number that supports SMS
   - Note down the phone number (e.g., +1234567890)

4. Get your credentials:
   - Account SID (starts with AC...)
   - Auth Token (found in Account Info)

## Step 2: Configure Firebase Functions

1. Install dependencies:
```bash
cd functions
npm install
```

2. Set Twilio configuration using secrets (new method):
```bash
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_PHONE_NUMBER
```

3. Deploy the functions:
```bash
firebase deploy --only functions
```

## Step 3: Test the Setup

1. Run your Flutter app
2. Set an emergency contact number in settings
3. Test the "Test Emergency SMS" button
4. Check your phone for the SMS message

## Step 4: Monitor and Debug

1. View function logs:
```bash
firebase functions:log
```

2. Check Firestore for emergency alerts:
   - Go to Firebase Console → Firestore
   - Look for `emergency_alerts` collection

## Troubleshooting

### Common Issues:

1. **"SMS service not configured properly"**
   - Check if Twilio config is set correctly
   - Verify the function was deployed

2. **"Failed to send SMS"**
   - Check Twilio account balance
   - Verify phone number format
   - Check function logs for detailed errors

3. **Function not found**
   - Make sure functions are deployed
   - Check function name in Flutter code

### Cost Considerations:

- Twilio free trial: $15 credit
- SMS cost: ~$0.0075 per message
- Free trial should handle ~2000 messages

### Security Notes:

- Never commit Twilio credentials to version control
- Use Firebase Functions config for sensitive data
- Consider implementing rate limiting for production

## Alternative SMS Services

If Twilio doesn't work for your region, consider:
- AWS SNS
- Google Cloud Messaging
- Regional SMS providers
- WhatsApp Business API

## Production Deployment

For production:
1. Upgrade Twilio account from trial
2. Set up proper error monitoring
3. Implement rate limiting
4. Add SMS delivery status tracking
5. Set up alerts for failed deliveries
