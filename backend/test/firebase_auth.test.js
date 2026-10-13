const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_test';
    await mongoose.connect(mongoUri);
  }

  await User.deleteMany({});
  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;
});

test.after(async () => {
  await User.deleteMany({});
  await mongoose.connection.close();
  if (mongoServer) {
    await mongoServer.stop();
  }
  server.close();
});

test('FIREBASE SYNC: Should provision a new user profile with verified Firebase token', async () => {
  const token = 'mock_firebase_uid101_newtraveler_+919876500001';

  const res = await fetch(`${baseUrl}/auth/firebase-sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: 'Rohan Mehta',
      city: 'Ahmedabad',
    }),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 201);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.isNewUser, true);
  assert.strictEqual(data.user.firebaseUid, 'uid101');
  assert.strictEqual(data.user.name, 'Rohan Mehta');
  assert.strictEqual(data.user.email, 'newtraveler@example.com');
  assert.strictEqual(data.user.phone, '+919876500001');
  assert.strictEqual(data.user.isVerified, true);
});

test('FIREBASE SYNC: Idempotent repeat calls must not create duplicates and return 200', async () => {
  const token = 'mock_firebase_uid101_newtraveler_+919876500001';

  const res = await fetch(`${baseUrl}/auth/firebase-sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: 'Rohan Mehta Updated',
    }),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.isNewUser, false);
  assert.strictEqual(data.user.firebaseUid, 'uid101');

  // Verify database count has only 1 user with this UID
  const count = await User.countDocuments({ firebaseUid: 'uid101' });
  assert.strictEqual(count, 1);
});

test('FIREBASE SYNC: Should safely associate existing email user with Firebase credentials', async () => {
  // Pre-existing user in MongoDB with email
  const existing = await User.create({
    name: 'Pooja Patel',
    email: 'pooja.patel@example.com',
    phone: '+919876500002',
    isVerified: true,
  });

  const token = 'mock_firebase_uid202_pooja.patel_+919876500002';

  const res = await fetch(`${baseUrl}/auth/firebase-sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({}),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.isNewUser, false);
  assert.strictEqual(data.user.firebaseUid, 'uid202');
  assert.strictEqual(data.user.id, existing._id.toString());
});

test('FIREBASE SYNC: Rejects missing token with 401', async () => {
  const res = await fetch(`${baseUrl}/auth/firebase-sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 401);
  assert.strictEqual(data.success, false);
});

test('FIREBASE SYNC: Rejects expired token with 401', async () => {
  const res = await fetch(`${baseUrl}/auth/firebase-sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer mock_firebase_expired',
    },
    body: JSON.stringify({}),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 401);
  assert.strictEqual(data.success, false);
});

test('PROTECTED ROUTE: Authenticates using verified Firebase ID token via dual-mode middleware', async () => {
  const token = 'mock_firebase_uid101_newtraveler_+919876500001';

  const res = await fetch(`${baseUrl}/auth/me`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.user.firebaseUid, 'uid101');
});

test('PROTECTED ROUTE: Suspended user with valid Firebase token is blocked with 403', async () => {
  // Suspend the user
  await User.updateOne(
    { firebaseUid: 'uid101' },
    {
      accountStatus: 'suspended',
      suspensionReason: 'Safety terms violation reported.',
      suspendedAt: new Date(),
    }
  );

  const token = 'mock_firebase_uid101_newtraveler_+919876500001';

  const res = await fetch(`${baseUrl}/auth/me`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });

  const data = await res.json();
  assert.strictEqual(res.status, 403);
  assert.strictEqual(data.errorCode, 'ACCOUNT_SUSPENDED');
  assert.strictEqual(data.suspensionReason, 'Safety terms violation reported.');

  // Unsuspend user for subsequent tests
  await User.updateOne({ firebaseUid: 'uid101' }, { accountStatus: 'active' });
});

test('PROTECTED ROUTE: Dual-Mode retains backward compatibility with legacy custom JWT', async () => {
  const user = await User.findOne({ firebaseUid: 'uid101' });
  const secret = getJwtSecret();
  const legacyJwt = jwt.sign({ id: user._id }, secret, { expiresIn: '1h' });

  const res = await fetch(`${baseUrl}/auth/me`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${legacyJwt}`,
    },
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.user.id, user._id.toString());
});

test('PROVIDER LINKING: Successfully links an additional provider to authenticated account', async () => {
  const token = 'mock_firebase_uid101_newtraveler_+919876500001';

  const res = await fetch(`${baseUrl}/auth/link-provider`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      providerId: 'phone',
      providerUid: 'phone_uid_888',
    }),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.message, 'Provider linked successfully.');

  // Repeat call is idempotent
  const repeatRes = await fetch(`${baseUrl}/auth/link-provider`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      providerId: 'phone',
      providerUid: 'phone_uid_888',
    }),
  });
  const repeatData = await repeatRes.json();
  assert.strictEqual(repeatRes.status, 200);
  assert.strictEqual(repeatData.message, 'Provider already linked to this profile.');
});
