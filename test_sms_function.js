// Test script to verify Firebase Functions SMS functionality
const admin = require('firebase-admin');

// Initialize Firebase Admin (you'll need to set GOOGLE_APPLICATION_CREDENTIALS)
admin.initializeApp();

async function testSMSFunction() {
  try {
    console.log('Testing SMS Function...');
    
    // Test data
    const testData = {
      phoneNumber: '+1234567890', // Replace with your test number
      message: '🚨 TEST ACCIDENT ALERT!\nThis is a test message from Safe Ride App.',
      location: {
        latitude: 40.7128,
        longitude: -74.0060
      },
      intensity: 5,
      timestamp: new Date().toISOString()
    };
    
    console.log('Test data:', JSON.stringify(testData, null, 2));
    
    // Call the function
    const result = await admin.functions().httpsCallable('sendEmergencySMS')(testData);
    
    console.log('✅ Function call successful!');
    console.log('Result:', result.data);
    
  } catch (error) {
    console.error('❌ Function call failed:');
    console.error('Error:', error.message);
    console.error('Code:', error.code);
    console.error('Details:', error.details);
  }
}

testSMSFunction();
