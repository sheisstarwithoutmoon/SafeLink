const admin = require('firebase-admin');
const config = require('./index');

let firebaseApp = null;

const initializeFirebase = () => {
  try {
    if (firebaseApp) {
      return firebaseApp;
    }

    // Initialize Firebase Admin SDK
    let serviceAccount;
    
    // Check if running on Render (environment variable exists)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      console.log('📋 Loading Firebase credentials from environment variable');
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } 
    // Fallback to file path (local development)
    else if (config.FIREBASE.privateKeyPath) {
      console.log('📋 Loading Firebase credentials from file');
      serviceAccount = require(`../../${config.FIREBASE.privateKeyPath}`);
    } else {
      throw new Error('Firebase service account not configured. Set FIREBASE_SERVICE_ACCOUNT environment variable or FIREBASE_PRIVATE_KEY_PATH.');
    }

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: config.FIREBASE.projectId || serviceAccount.project_id,
    });

    console.log('✅ Firebase Admin SDK initialized');
    console.log(`📱 Project ID: ${serviceAccount.project_id}`);
    return firebaseApp;
  } catch (error) {
    console.error('❌ Error initializing Firebase:', error.message);
    throw error;
  }
};

const getFirebaseApp = () => {
  if (!firebaseApp) {
    return initializeFirebase();
  }
  return firebaseApp;
};

module.exports = {
  initializeFirebase,
  getFirebaseApp,
  admin,
};
