const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { Server } = require('socket.io');
const ioClient = require('socket.io-client');
const jwt = require('jsonwebtoken');

const app = require('../src/app');
const initSocketService = require('../src/services/socketService');
const { getJwtSecret } = require('../src/config/jwt');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const AuditLog = require('../src/models/AuditLog');

let mongoServer;
let server;
let baseUrl;
let io;
let socketPort;

let adminUser;
let adminToken;
let secondAdminUser;
let secondAdminToken;
let driverUser;
let driverToken;
let passengerUser;
let passengerToken;
let testVehicle;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_suspension_test';
    await mongoose.connect(mongoUri);
  }

  await User.init();
  await Vehicle.init();
  await AuditLog.init();

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await AuditLog.deleteMany({});

  // 1. Root Admin User
  adminUser = await User.create({
    name: 'Primary Admin',
    email: 'admin.suspension@sahyan.app',
    phone: '+919999911111',
    password: 'AdminPassword123!',
    role: 'admin',
    isVerified: true,
  });
  adminToken = jwt.sign({ id: adminUser._id, role: adminUser.role }, getJwtSecret(), { expiresIn: '2h' });

  // 2. Second Admin User
  secondAdminUser = await User.create({
    name: 'Secondary Admin',
    email: 'second.admin@sahyan.app',
    phone: '+919999922222',
    password: 'AdminPassword123!',
    role: 'admin',
    isVerified: true,
  });
  secondAdminToken = jwt.sign({ id: secondAdminUser._id, role: secondAdminUser.role }, getJwtSecret(), { expiresIn: '2h' });

  // 3. Eligible Driver User
  driverUser = await User.create({
    name: 'Karan Driver',
    email: 'karan.driver@example.com',
    phone: '+919811199999',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
    capabilities: { canDrive: true, canRide: true },
    driverProfile: {
      onboardingStatus: 'approved',
      licenseNumber: 'GJ01-2024-8888',
    },
  });
  driverToken = jwt.sign({ id: driverUser._id, role: driverUser.role }, getJwtSecret(), { expiresIn: '2h' });

  testVehicle = await Vehicle.create({
    owner: driverUser._id,
    registrationNumber: 'GJ-01-KD-8888',
    make: 'Maruti',
    model: 'Brezza',
    year: 2023,
    seatCapacity: 4,
    color: 'Silver',
    vehicleType: 'suv',
  });

  // 4. Passenger-only User
  passengerUser = await User.create({
    name: 'Priya Passenger',
    email: 'priya.passenger@example.com',
    phone: '+919822288888',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
    capabilities: { canDrive: false, canRide: true },
    driverProfile: {
      onboardingStatus: 'not_started',
    },
  });
  passengerToken = jwt.sign({ id: passengerUser._id, role: passengerUser.role }, getJwtSecret(), { expiresIn: '2h' });

  // Start Express API server & Socket.IO server
  server = http.createServer(app);
  io = new Server(server, {
    cors: { origin: '*' },
    transports: ['websocket'],
  });
  initSocketService(io);

  await new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      baseUrl = `http://127.0.0.1:${address.port}/api/v1`;
      socketPort = address.port;
      resolve();
    });
  });
});

test.after(async () => {
  if (io) io.close();
  if (server) await new Promise((res) => server.close(res));
  await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
});

test('SUSPENSION API: 1. Administrator successfully suspends eligible driver with valid reason', async () => {
  const res = await fetch(`${baseUrl}/admin/users/${driverUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      reason: 'Repeated non-compliance with passenger safety guidelines during route transit.',
    }),
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.user.accountStatus, 'suspended');
  assert.equal(data.user.suspensionReason, 'Repeated non-compliance with passenger safety guidelines during route transit.');
  assert.ok(data.user.suspendedAt);
  assert.equal(data.user.suspendedBy.toString(), adminUser._id.toString());

  // Confirm DB persistence
  const persisted = await User.findById(driverUser._id);
  assert.equal(persisted.accountStatus, 'suspended');

  // Verify audit log record
  const log = await AuditLog.findOne({ action: 'DRIVER_SUSPENDED', targetUser: driverUser._id });
  assert.ok(log);
  assert.equal(log.admin.toString(), adminUser._id.toString());
  assert.equal(log.reason, 'Repeated non-compliance with passenger safety guidelines during route transit.');
});

test('SUSPENSION API: 2. Missing or invalid reason (< 5 characters) is rejected with 400', async () => {
  // Temporary un-suspend to test validation
  await User.findByIdAndUpdate(driverUser._id, { accountStatus: 'active', suspensionReason: '' });

  const resTooShort = await fetch(`${baseUrl}/admin/users/${driverUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({ reason: 'bad' }),
  });

  assert.equal(resTooShort.status, 400);
  const dataTooShort = await resTooShort.json();
  assert.equal(dataTooShort.success, false);

  const resMissing = await fetch(`${baseUrl}/admin/users/${driverUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({}),
  });

  assert.equal(resMissing.status, 400);

  // Re-suspend driver for downstream tests
  await fetch(`${baseUrl}/admin/users/${driverUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      reason: 'Repeated non-compliance with passenger safety guidelines during route transit.',
    }),
  });
});

test('SUSPENSION API: 3. Non-admin users cannot suspend or reactivate accounts (403)', async () => {
  const resSuspend = await fetch(`${baseUrl}/admin/users/${driverUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({ reason: 'Unauthorized attempt by passenger.' }),
  });
  assert.equal(resSuspend.status, 403);

  const resReactivate = await fetch(`${baseUrl}/admin/users/${driverUser._id}/reactivate`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({ reason: 'Unauthorized attempt by passenger.' }),
  });
  assert.equal(resReactivate.status, 403);
});

test('SUSPENSION API: 4. Administrator cannot suspend their own account through driver endpoint (403)', async () => {
  const res = await fetch(`${baseUrl}/admin/users/${adminUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({ reason: 'Accidental self-suspension attempt.' }),
  });

  assert.equal(res.status, 403);
  const data = await res.json();
  assert.equal(data.success, false);
});

test('SUSPENSION API: 5. Administrator cannot suspend another administrator account (403)', async () => {
  const res = await fetch(`${baseUrl}/admin/users/${secondAdminUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({ reason: 'Attempting to suspend second administrator.' }),
  });

  assert.equal(res.status, 403);
  const data = await res.json();
  assert.equal(data.success, false);
});

test('SUSPENSION API: 6. Nonexistent account returns 404', async () => {
  const fakeId = new mongoose.Types.ObjectId();
  const res = await fetch(`${baseUrl}/admin/users/${fakeId}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({ reason: 'Valid reason for nonexistent target user.' }),
  });

  assert.equal(res.status, 404);
});

test('SUSPENSION API: 7. Passenger-only accounts cannot be suspended through driver endpoint (400)', async () => {
  const res = await fetch(`${baseUrl}/admin/users/${passengerUser._id}/suspend`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({ reason: 'Attempting driver suspension on passenger-only account.' }),
  });

  assert.equal(res.status, 400);
  const data = await res.json();
  assert.equal(data.success, false);
  assert.match(data.message, /passenger-only/i);
});

test('SUSPENSION SECURITY: 8. Existing JWTs are rejected immediately on subsequent protected requests with 403 ACCOUNT_SUSPENDED', async () => {
  // driverUser is currently suspended
  const res = await fetch(`${baseUrl}/auth/me`, {
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });

  assert.equal(res.status, 403);
  const data = await res.json();
  assert.equal(data.success, false);
  assert.equal(data.errorCode, 'ACCOUNT_SUSPENDED');
  assert.ok(data.suspensionReason);
  assert.ok(data.suspendedAt);
});

test('SUSPENSION SECURITY: 9. Login attempts for suspended accounts do not issue usable tokens (403)', async () => {
  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: driverUser.email,
      password: 'Password123!',
    }),
  });

  assert.equal(res.status, 403);
  const data = await res.json();
  assert.equal(data.success, false);
  assert.equal(data.errorCode, 'ACCOUNT_SUSPENDED');
  assert.equal(data.token, undefined);
  assert.equal(data.accessToken, undefined);
});

test('SUSPENSION SECURITY: 10. Protected APIs reject suspended accounts across endpoints', async () => {
  // Attempting to fetch own rides while suspended
  const resRides = await fetch(`${baseUrl}/rides/my`, {
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });
  assert.equal(resRides.status, 403);
  const dataRides = await resRides.json();
  assert.equal(dataRides.errorCode, 'ACCOUNT_SUSPENDED');

  // Attempting to update user profile while suspended
  const resProfile = await fetch(`${baseUrl}/users/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify({ name: 'Hacked Profile' }),
  });
  assert.equal(resProfile.status, 403);
  const dataProfile = await resProfile.json();
  assert.equal(dataProfile.errorCode, 'ACCOUNT_SUSPENDED');
});

test('SUSPENSION SECURITY: 11. Socket.IO handshake rejects suspended users with ACCOUNT_SUSPENDED', async () => {
  const client = ioClient(`http://127.0.0.1:${socketPort}`, {
    auth: { token: driverToken },
    transports: ['websocket'],
    reconnection: false,
    timeout: 3000,
  });

  const connectError = await new Promise((resolve) => {
    client.on('connect_error', (err) => {
      resolve(err);
    });
    client.on('connect', () => {
      client.disconnect();
      resolve(null);
    });
  });

  assert.ok(connectError, 'Socket connection should fail for suspended driver');
  assert.equal(connectError.message, 'ACCOUNT_SUSPENDED');
  assert.equal(connectError.data.errorCode, 'ACCOUNT_SUSPENDED');
  assert.equal(connectError.data.code, 403);
});

test('REACTIVATION: 12. Reactivation restores access and preserves immutable audit history', async () => {
  const res = await fetch(`${baseUrl}/admin/users/${driverUser._id}/reactivate`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      reason: 'Driver successfully resolved verification discrepancy and signed updated terms.',
    }),
  });

  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.success, true);
  assert.equal(data.user.accountStatus, 'active');
  assert.equal(data.user.suspensionReason, '');
  assert.equal(data.user.suspendedAt, null);

  // Verify audit log has BOTH the initial suspensions and reactivation
  const logs = await AuditLog.find({ targetUser: driverUser._id }).sort({ createdAt: 1 });
  assert.equal(logs.length, 3);
  assert.equal(logs[0].action, 'DRIVER_SUSPENDED');
  assert.equal(logs[1].action, 'DRIVER_SUSPENDED');
  assert.equal(logs[2].action, 'DRIVER_REACTIVATED');

  // Verify driver can now authenticate and access protected endpoints
  const profileRes = await fetch(`${baseUrl}/auth/me`, {
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });
  assert.equal(profileRes.status, 200);
  const profileData = await profileRes.json();
  assert.equal(profileData.success, true);
  assert.equal(profileData.data.user.accountStatus, 'active');
});

test('BASELINE INTEGRITY: 13. Previously active users continue to authenticate and use existing APIs normally', async () => {
  const passengerMe = await fetch(`${baseUrl}/auth/me`, {
    headers: {
      Authorization: `Bearer ${passengerToken}`,
    },
  });
  assert.equal(passengerMe.status, 200);
  const passData = await passengerMe.json();
  assert.equal(passData.data.user.accountStatus, 'active');

  const adminStats = await fetch(`${baseUrl}/admin/stats`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
  });
  assert.equal(adminStats.status, 200);
});
