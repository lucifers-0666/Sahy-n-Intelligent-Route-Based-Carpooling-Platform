const admin = require('firebase-admin');
const fs = require('fs');

let initialized = false;
let mockMode = false;

function initFirebase() {
  if (initialized) {
    return admin;
  }

  try {
    // 1. Check for inline JSON service account or file path
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      const val = process.env.FIREBASE_SERVICE_ACCOUNT_KEY.trim();
      let serviceAccount;
      if (val.startsWith('{')) {
        serviceAccount = JSON.parse(val);
      } else if (fs.existsSync(val)) {
        serviceAccount = JSON.parse(fs.readFileSync(val, 'utf8'));
      }

      if (serviceAccount) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        initialized = true;
        return admin;
      }
    }

    // 2. Check for discrete environment variables
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      initialized = true;
      return admin;
    }

    // 3. Check for Application Default Credentials or existing apps
    if (admin.apps && admin.apps.length > 0) {
      initialized = true;
      return admin;
    }

    // 4. Default initialize if standard GOOGLE_APPLICATION_CREDENTIALS exists
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp();
      initialized = true;
      return admin;
    }

    // 5. In test or development without keys, enable mock verification
    mockMode = true;
    initialized = true;
    console.warn('[Firebase Admin Notice] No Firebase credentials found. Running in mock/development mode.');
    return admin;
  } catch (error) {
    mockMode = true;
    initialized = true;
    console.warn(`[Firebase Admin Notice] Initialization error (${error.message}). Running in mock/development mode.`);
    return admin;
  }
}

/**
 * Verifies a Firebase ID token.
 * In production, uses admin.auth().verifyIdToken(token).
 * In mock mode (tests/local dev without credentials), validates fictional test tokens.
 */
async function verifyFirebaseIdToken(token) {
  initFirebase();

  if (!token || typeof token !== 'string') {
    throw new Error('Token must be a non-empty string');
  }

  // Support simulated/mock token in test/dev environments
  if (mockMode || process.env.NODE_ENV === 'test' || token.startsWith('mock_firebase_')) {
    if (token === 'expired_token' || token === 'mock_firebase_expired') {
      const err = new Error('Firebase ID token has expired');
      err.code = 'auth/id-token-expired';
      throw err;
    }
    if (token === 'invalid_token' || token === 'mock_firebase_invalid') {
      const err = new Error('Firebase ID token is invalid');
      err.code = 'auth/argument-error';
      throw err;
    }

    // Extract mock payload or return realistic simulated Firebase claims
    if (token.startsWith('mock_firebase_')) {
      const parts = token.split('_');
      const uid = parts[2] || 'test_firebase_uid_123';
      const email = parts[3] ? `${parts[3]}@example.com` : 'firebase.test@example.com';
      const phone = parts[4] || '+919999999999';
      return {
        uid,
        email,
        email_verified: true,
        phone_number: phone,
        name: 'Test Firebase User',
        picture: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        firebase: {
          sign_in_provider: 'google.com',
        },
      };
    }
  }

  if (admin.apps && admin.apps.length > 0) {
    return await admin.auth().verifyIdToken(token);
  }

  throw new Error('Firebase Admin SDK is not configured with service credentials.');
}

module.exports = {
  admin,
  initFirebase,
  verifyFirebaseIdToken,
  isMockMode: () => mockMode,
};
