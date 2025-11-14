const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendEmergencySMS = functions.https.onCall(async (data, context) => {
  console.log('=== FUNCTION CALLED v2.0 ===');
  console.log('Received data:', data);
  console.log('Auth UID:', context.auth?.uid || 'unauthenticated');
  
  try {
    // Handle case where data might be null or undefined
    if (!data) {
      console.error('No data received');
      throw new functions.https.HttpsError(
        'invalid-argument',
        'No data received'
      );
    }
    
    // Validate input with detailed logging
    console.log('Validating phoneNumber:', data.phoneNumber);
    console.log('Validating message:', data.message);
    
    if (!data.phoneNumber || !data.message) {
      console.error('Validation failed:');
      console.error('- phoneNumber:', data.phoneNumber, '(type:', typeof data.phoneNumber, ')');
      console.error('- message:', data.message, '(type:', typeof data.message, ')');
      console.error('- Full data object:', data);
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Phone number and message are required'
      );
    }

    
    // Format the message
    let msg = data.message;
    
    if (data.location && data.location.latitude && data.location.longitude) {
      msg += `\n\nLocation: https://maps.google.com/?q=${data.location.latitude},${data.location.longitude}`;
    }
    
    if (data.intensity) {
      msg += `\nIntensity: ${data.intensity}`;
    }
    
    if (data.timestamp) {
      msg += `\nTime: ${data.timestamp}`;
    }

    console.log('Sending SMS to:', data.phoneNumber);

    // Call Twilio REST API using fetch
    const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
    const auth = Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64');
    
    const params = new URLSearchParams();
    params.append('To', data.phoneNumber);
    params.append('From', TWILIO_PHONE);
    params.append('Body', msg);

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: params.toString()
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Twilio error:', errorText);
      throw new Error(`Twilio API failed: ${response.status}`);
    }

    const result = await response.json();
    console.log('✓ SMS sent successfully, SID:', result.sid);

    // Save to Firestore
    await admin.firestore().collection('emergency_alerts').add({
      phoneNumber: data.phoneNumber,
      message: msg,
      twilioSid: result.sid,
      twilioStatus: result.status,
      status: 'sent',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Return simple response
    return {
      success: true,
      messageId: result.sid,
      message: 'SMS sent successfully'
    };

  } catch (error) {
    console.error('ERROR:', error.message);
    
    // Log error to Firestore
    try {
      await admin.firestore().collection('emergency_alerts').add({
        phoneNumber: data.phoneNumber || 'unknown',
        error: error.message,
        status: 'failed',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (logError) {
      console.error('Failed to log error:', logError.message);
    }

    // Throw error
    throw new functions.https.HttpsError(
      'internal',
      `Failed to send SMS: ${error.message}`
    );
  }
});

// Optional: Function to get emergency alerts
exports.getEmergencyAlerts = functions.https.onRequest(async (req, res) => {
  try {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'GET');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    if (req.method !== 'GET') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const limit = parseInt(req.query.limit) || 10;
    
    const snapshot = await admin.firestore()
      .collection('emergency_alerts')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const alerts = [];
    snapshot.forEach(doc => {
      alerts.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.status(200).json({ alerts });

  } catch (error) {
    console.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});