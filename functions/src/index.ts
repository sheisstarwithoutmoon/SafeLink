import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface SMSRequest {
  phoneNumber: string;
  message: string;
  location?: {
    latitude: number;
    longitude: number;
  };
  intensity?: number;
  timestamp?: string;
}

interface TwilioResponse {
  sid: string;
  status: string;
  message?: string;
  code?: number;
}

export const sendEmergencySMS = functions.https.onCall(async (request) => {
  const data: SMSRequest = request.data;
  
  console.log('=== FUNCTION CALLED ===');
  console.log('Phone:', data.phoneNumber);
  console.log('Message:', data.message);
  
  try {
    // Validate
    if (!data.phoneNumber || !data.message) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Phone number and message required'
      );
    }

    // 🔥 PUT YOUR REAL TWILIO CREDENTIALS HERE
    const TWILIO_ACCOUNT_SID = 'AC5143c4f189a13c8fa71dec8c7d9a9738';
    const TWILIO_AUTH_TOKEN = 'e6e84bd412fb16d11b94398172775cbb';
    const TWILIO_PHONE = '+15079363358';

    // Format message
    let msg = data.message;
    if (data.location) {
      msg += `\n\nLocation: https://maps.google.com/?q=${data.location.latitude},${data.location.longitude}`;
    }
    if (data.intensity) {
      msg += `\nIntensity: ${data.intensity}`;
    }
    if (data.timestamp) {
      msg += `\nTime: ${data.timestamp}`;
    }

    console.log('Calling Twilio API...');

    // Use fetch API (no circular references!)
    const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
    const auth = Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64');
    
    const body = new URLSearchParams({
      To: data.phoneNumber,
      From: TWILIO_PHONE,
      Body: msg
    });

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: body.toString()
    });

    const result = await response.json() as TwilioResponse;

    if (!response.ok) {
      console.error('Twilio error:', result);
      throw new Error(result.message || `Twilio API failed with code ${result.code}`);
    }

    console.log('✓ SMS sent:', result.sid);

    // Save to Firestore
    await admin.firestore().collection('emergency_alerts').add({
      phoneNumber: data.phoneNumber,
      message: msg,
      twilioSid: result.sid,
      twilioStatus: result.status,
      status: 'sent',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Return simple object
    return {
      success: true,
      messageId: result.sid,
      status: result.status,
      message: 'SMS sent successfully'
    };

  } catch (error: any) {
    console.error('ERROR:', error.message || error);
    
    // Log error to Firestore
    try {
      await admin.firestore().collection('emergency_alerts').add({
        phoneNumber: data.phoneNumber,
        error: error.message || String(error),
        status: 'failed',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (e) {
      console.error('Failed to log error:', e);
    }

    throw new functions.https.HttpsError(
      'internal',
      `SMS failed: ${error.message || String(error)}`
    );
  }
});

export const getEmergencyAlerts = functions.https.onRequest(async (req, res) => {
  const cors = require('cors')({ origin: true });
  
  return cors(req, res, async () => {
    try {
      if (req.method !== 'GET') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const limit = parseInt(req.query.limit as string) || 10;
      const alerts = await admin.firestore()
        .collection('emergency_alerts')
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      const alertsData = alerts.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      return res.status(200).json({ alerts: alertsData });

    } catch (error) {
      console.error('Error fetching alerts:', error);
      return res.status(500).json({ error: 'Failed to fetch alerts' });
    }
  });
});