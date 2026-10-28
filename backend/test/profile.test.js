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

let userA;
let tokenA;
let userB;
let tokenB;

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

  // Create User A
  userA = await User.create({
    name: 'Arjun Patel',
    email: 'arjun.profile@example.com',
    phone: '+919876543210',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  tokenA = jwt.sign({ id: userA._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // Create User B
  userB = await User.create({
    name: 'Rohan Sharma',
    email: 'rohan.profile@example.com',
    phone: '+919876543211',
    password: 'Password123@#',
    city: 'Surat',
    isVerified: false,
  });
  tokenB = jwt.sign({ id: userB._id.toString() }, getJwtSecret(), { expiresIn: '1h' });
});

test.after(async () => {
  await User.deleteMany({});
  await mongoose.connection.close();
  if (mongoServer) {
    await mongoServer.stop();
  }
  server.close();
});

test('PROFILE: GET /users/profile rejects unauthenticated request with 401', async () => {
  const res = await fetch(`${baseUrl}/users/profile`);
  assert.strictEqual(res.status, 401);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('PROFILE: GET /users/profile returns authenticated user profile', async () => {
  const res = await fetch(`${baseUrl}/users/profile`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.name, 'Arjun Patel');
  assert.strictEqual(data.data.email, 'arjun.profile@example.com');
  assert.strictEqual(data.data.phone, '+919876543210');
  assert.strictEqual(data.data.city, 'Ahmedabad');
  assert.strictEqual(data.data.password, undefined);
  assert.strictEqual(data.data.otpInfo, undefined);
  assert.strictEqual(data.data.resetPasswordInfo, undefined);
});

test('PROFILE: PUT /users/profile updates name, city, bio successfully', async () => {
  const updatePayload = {
    name: 'Arjun K. Patel',
    city: 'Gandhinagar',
    bio: 'Frequent daily commuter between Gandhinagar and Ahmedabad.',
  };

  const res = await fetch(`${baseUrl}/users/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify(updatePayload),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.name, 'Arjun K. Patel');
  assert.strictEqual(data.data.city, 'Gandhinagar');
  assert.strictEqual(data.data.bio, 'Frequent daily commuter between Gandhinagar and Ahmedabad.');
});

test('PROFILE: PUT /users/profile strictly rejects/ignores protected fields', async () => {
  const exploitPayload = {
    role: 'admin',
    isVerified: false,
    rating: { average: 5.0, count: 999 },
    capabilities: { canDrive: true, canRide: false },
    driverProfile: { onboardingStatus: 'approved' },
    password: 'HackedPassword123@#',
  };

  const res = await fetch(`${baseUrl}/users/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify(exploitPayload),
  });

  assert.strictEqual(res.status, 200);
  const dbUser = await User.findById(userA._id);
  assert.strictEqual(dbUser.role, 'user');
  assert.strictEqual(dbUser.isVerified, true);
  assert.strictEqual(dbUser.capabilities.canDrive, false);
  assert.strictEqual(dbUser.driverProfile.onboardingStatus, 'not_started');
});

test('PROFILE: PUT /users/profile updates profile image / avatar successfully', async () => {
  const avatarUrl = 'https://api.dicebear.com/7.x/adventurer/png?seed=Ahmedabad';
  const res = await fetch(`${baseUrl}/users/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      profileImage: avatarUrl,
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.profileImage, avatarUrl);

  const dbUser = await User.findById(userA._id);
  assert.strictEqual(dbUser.profileImage, avatarUrl);
});

test('PROFILE: PUT /users/profile-image dedicated endpoint updates avatar', async () => {
  const customAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256';
  const res = await fetch(`${baseUrl}/users/profile-image`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      avatar: customAvatar,
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.profileImage, customAvatar);
});

test('PROFILE: PUT /users/profile-image accepts default preset avatar for driver', async () => {
  // Give userB driver capability
  await User.findByIdAndUpdate(userB._id, { 'capabilities.canDrive': true, 'driverProfile.onboardingStatus': 'approved' });

  const driverAvatar = 'https://api.dicebear.com/7.x/bottts/png?seed=SahyanDriver';
  const res = await fetch(`${baseUrl}/users/profile/image`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify({
      profilePhoto: driverAvatar,
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.profileImage, driverAvatar);
});

test('PROFILE: PUT /users/profile-image clears profile image when empty', async () => {
  const res = await fetch(`${baseUrl}/users/profile-image`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      profileImage: '',
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.profileImage, '');
});

test('PROFILE: PUT /users/profile rejects empty name or city and oversized bio', async () => {
  const emptyNameRes = await fetch(`${baseUrl}/users/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({ name: '   ' }),
  });
  assert.strictEqual(emptyNameRes.status, 400);

  const longBio = 'a'.repeat(141);
  const longBioRes = await fetch(`${baseUrl}/users/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({ bio: longBio }),
  });
  assert.strictEqual(longBioRes.status, 400);
});

test('PREFERENCES: PUT /users/preferences updates notifications, smoking, pets', async () => {
  const payload = {
    notifications: false,
    allowSmoking: true,
    allowPets: true,
  };

  const res = await fetch(`${baseUrl}/users/preferences`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify(payload),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.notifications, false);
  assert.strictEqual(data.data.allowSmoking, true);
  assert.strictEqual(data.data.allowPets, true);

  const dbUser = await User.findById(userA._id);
  assert.strictEqual(dbUser.preferences.notifications, false);
  assert.strictEqual(dbUser.preferences.allowSmoking, true);
  assert.strictEqual(dbUser.preferences.allowPets, true);
});

test('PREFERENCES: PUT /users/preferences rejects non-boolean values with 400', async () => {
  const invalidPayload = {
    notifications: 'true',
    allowSmoking: 1,
  };

  const res = await fetch(`${baseUrl}/users/preferences`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify(invalidPayload),
  });

  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.strictEqual(data.message, 'notifications preference must be a boolean');
});

test('EMERGENCY CONTACTS: CRUD flow and validation', async () => {
  // 1. Initial list should be empty
  let listRes = await fetch(`${baseUrl}/users/emergency-contacts`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(listRes.status, 200);
  let listData = await listRes.json();
  assert.strictEqual(listData.data.length, 0);

  // 2. Reject invalid phone format
  const invalidPhoneRes = await fetch(`${baseUrl}/users/emergency-contacts`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      name: 'Pooja Patel',
      phone: '12345',
      relationship: 'Sister',
    }),
  });
  assert.strictEqual(invalidPhoneRes.status, 400);

  // 3. Add valid contact
  const createRes = await fetch(`${baseUrl}/users/emergency-contacts`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      name: 'Pooja Patel',
      phone: '9825012345',
      relationship: 'Sister',
    }),
  });
  assert.strictEqual(createRes.status, 201);
  const createData = await createRes.json();
  assert.strictEqual(createData.success, true);
  assert.strictEqual(createData.data.name, 'Pooja Patel');
  assert.strictEqual(createData.data.phone, '+919825012345');
  assert.strictEqual(createData.data.relationship, 'Sister');
  const contactId = createData.data._id;
  assert.ok(contactId);

  // 4. Update contact
  const updateRes = await fetch(`${baseUrl}/users/emergency-contacts/${contactId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      name: 'Pooja A. Patel',
      relationship: 'Family',
    }),
  });
  assert.strictEqual(updateRes.status, 200);
  const updateData = await updateRes.json();
  assert.strictEqual(updateData.data.name, 'Pooja A. Patel');
  assert.strictEqual(updateData.data.relationship, 'Family');

  // 5. Multi-user isolation: User B cannot update User A's contact
  const userBUpdateRes = await fetch(`${baseUrl}/users/emergency-contacts/${contactId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify({ name: 'Malicious Edit' }),
  });
  assert.strictEqual(userBUpdateRes.status, 404);

  // 6. Delete contact
  const deleteRes = await fetch(`${baseUrl}/users/emergency-contacts/${contactId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(deleteRes.status, 200);

  // 7. Verify list is now empty
  listRes = await fetch(`${baseUrl}/users/emergency-contacts`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  listData = await listRes.json();
  assert.strictEqual(listData.data.length, 0);
});

test('DRIVER ONBOARDING: GET /users/driver-status returns initial state', async () => {
  const res = await fetch(`${baseUrl}/users/driver-status`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.onboardingStatus, 'not_started');
  assert.strictEqual(data.data.canDrive, false);
  assert.strictEqual(data.data.canRide, true);
  assert.strictEqual(data.data.isVerified, true);
});

test('DRIVER ONBOARDING: POST /users/driver-application enforces phone verification and validation', async () => {
  // 1. Unverified user rejected
  const unverifiedRes = await fetch(`${baseUrl}/users/driver-application`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify({ licenseNumber: 'GJ0120220005678' }),
  });
  assert.strictEqual(unverifiedRes.status, 400);
  const unverifiedData = await unverifiedRes.json();
  assert.match(unverifiedData.message, /phone number verification is required/i);

  // 2. Missing license number rejected
  const missingRes = await fetch(`${baseUrl}/users/driver-application`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({ licenseNumber: '   ' }),
  });
  assert.strictEqual(missingRes.status, 400);

  // 3. Valid submission succeeds
  const validRes = await fetch(`${baseUrl}/users/driver-application`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      licenseNumber: 'gj0120220009999',
      licenseDocUrl: 'https://cdn.sahyan.internal/docs/dl_arjun.pdf',
    }),
  });
  assert.strictEqual(validRes.status, 200);
  const validData = await validRes.json();
  assert.strictEqual(validData.success, true);
  assert.strictEqual(validData.data.driverProfile.onboardingStatus, 'submitted');
  assert.strictEqual(validData.data.driverProfile.licenseNumber, 'GJ0120220009999');

  // 4. Verify updated driver status reflects submitted
  const statusRes = await fetch(`${baseUrl}/users/driver-status`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(statusRes.status, 200);
  const statusData = await statusRes.json();
  assert.strictEqual(statusData.data.onboardingStatus, 'submitted');
  assert.strictEqual(statusData.data.licenseNumber, 'GJ0120220009999');
  assert.strictEqual(statusData.data.canDrive, false);
});

