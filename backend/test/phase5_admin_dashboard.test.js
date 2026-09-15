const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');
const Report = require('../src/models/Report');
const Notification = require('../src/models/Notification');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let adminUser;
let adminToken;
let regularUser;
let regularToken;
let pendingDriverUser;
let testVehicle;
let testRide;
let testReport;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_phase5_test';
    await mongoose.connect(mongoUri);
  }

  await User.init();
  await Vehicle.init();
  await Ride.init();
  await Booking.init();
  await Report.init();
  await Notification.init();

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});
  await Report.deleteMany({});
  await Notification.deleteMany({});

  // 1. Create Admin User
  adminUser = await User.create({
    name: 'Sahyan Root Admin',
    email: 'admin@sahyan.app',
    phone: '+919999988888',
    password: 'AdminPassword123!',
    role: 'admin',
    isVerified: true,
  });
  adminToken = jwt.sign({ id: adminUser._id, role: adminUser.role }, getJwtSecret(), { expiresIn: '1h' });

  // 2. Create Regular User
  regularUser = await User.create({
    name: 'Normal Passenger',
    email: 'regular@example.com',
    phone: '+919876500000',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
  });
  regularToken = jwt.sign({ id: regularUser._id, role: regularUser.role }, getJwtSecret(), { expiresIn: '1h' });

  // 3. Create Pending Driver User
  pendingDriverUser = await User.create({
    name: 'Rahul Applicant',
    email: 'rahul.driver@example.com',
    phone: '+919811122233',
    password: 'Password123!',
    role: 'user',
    isVerified: false,
    capabilities: { canDrive: false, canRide: true },
    driverProfile: {
      onboardingStatus: 'submitted',
      licenseNumber: 'GJ01-2024-009988',
      licenseDocUrl: 'https://sahyan.app/docs/license_rahul.png',
      rcDocUrl: 'https://sahyan.app/docs/rc_rahul.png',
    },
  });

  // 4. Create Vehicle for Pending Driver
  testVehicle = await Vehicle.create({
    owner: pendingDriverUser._id,
    registrationNumber: 'GJ-01-RA-9988',
    make: 'Hyundai',
    model: 'Creta',
    year: 2023,
    color: 'Forest Green',
    seatCapacity: 4,
    vehicleType: 'suv',
  });

  // 5. Create a Scheduled Ride
  testRide = await Ride.create({
    driver: pendingDriverUser._id,
    vehicle: testVehicle._id,
    origin: {
      name: 'SG Highway, Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    destination: {
      name: 'Alkapuri, Vadodara',
      latitude: 22.3072,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    route: {
      encodedPolyline: 'u{~nE_w~vOu`@z_@',
      distanceMeters: 110000,
      durationSeconds: 5400,
    },
    departureTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
    estimatedArrivalTime: new Date(Date.now() + 26 * 60 * 60 * 1000),
    totalSeats: 3,
    availableSeats: 3,
    contributionPerSeat: 260,
    status: 'scheduled',
  });

  // 6. Create a Completed Booking to test fuel split and CO2 aggregation
  await Booking.create({
    passenger: regularUser._id,
    ride: testRide._id,
    requestedSeats: 2,
    contributionPerSeat: 260,
    totalContribution: 520,
    pickup: {
      name: 'Iscon Cross Roads',
      latitude: 23.029,
      longitude: 72.507,
      point: { type: 'Point', coordinates: [72.507, 23.029] },
    },
    drop: {
      name: 'Alkapuri',
      latitude: 22.307,
      longitude: 73.181,
      point: { type: 'Point', coordinates: [73.181, 22.307] },
    },
    status: 'completed',
  });

  // 7. Create a Safety Report
  testReport = await Report.create({
    reporter: regularUser._id,
    reportedUser: pendingDriverUser._id,
    ride: testRide._id,
    type: 'safety_concern',
    title: 'Speeding on NE1 Corridor',
    description: 'Vehicle exceeded highway corridor recommended speed limits near Anand toll.',
    severity: 'high',
    status: 'open',
  });

  server = app.listen(0);
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}`;
});

test.after(async () => {
  if (server) await server.close();
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }
  if (mongoServer) await mongoServer.stop();
});

test('1. Unauthenticated request to /api/v1/admin/stats is rejected with 401', async () => {
  const res = await fetch(`${baseUrl}/api/v1/admin/stats`);
  assert.strictEqual(res.status, 401);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('2. Regular user (non-admin) is rejected with 403 Forbidden', async () => {
  const res = await fetch(`${baseUrl}/api/v1/admin/stats`, {
    headers: {
      Authorization: `Bearer ${regularToken}`,
    },
  });
  assert.strictEqual(res.status, 403);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /Administrative privileges required/i);
});

test('3. Admin user retrieves aggregate statistics with 200 OK', async () => {
  const res = await fetch(`${baseUrl}/api/v1/admin/stats`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(typeof data.data.totalUsers, 'number');
  assert.strictEqual(typeof data.data.pendingVerifications, 'number');
  assert.strictEqual(typeof data.data.completedBookings, 'number');
  assert.strictEqual(data.data.totalFuelSplit, 520);
  assert.ok(data.data.totalCo2SavedKg >= 4);
  assert.strictEqual(data.data.systemHealth.database, 'connected');
});

test('4. Admin retrieves paginated users list with verification status filter', async () => {
  const res = await fetch(`${baseUrl}/api/v1/admin/users?status=pending`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.ok(Array.isArray(data.data.users));
  assert.strictEqual(data.data.users.length, 1);
  assert.strictEqual(data.data.users[0].name, 'Rahul Applicant');
  assert.strictEqual(data.data.users[0].driverProfile.onboardingStatus, 'submitted');
  assert.ok(data.data.users[0].vehicle, 'Vehicle should be attached');
  assert.strictEqual(data.data.users[0].vehicle.registrationNumber, 'GJ-01-RA-9988');
});

test('5. Admin approves pending driver verification with 200 and triggers notification', async () => {
  const res = await fetch(`${baseUrl}/api/v1/admin/users/${pendingDriverUser._id}/verify`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      status: 'approved',
    }),
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.user.isVerified, true);
  assert.strictEqual(data.data.user.canDrive, true);
  assert.strictEqual(data.data.user.onboardingStatus, 'approved');

  // Verify notification created
  const notif = await Notification.findOne({ user: pendingDriverUser._id, category: 'system' });
  assert.ok(notif, 'Notification should be created for driver');
  assert.match(notif.title, /Approved/i);
});

test('6. Admin rejects driver verification with reason and updates status to rejected', async () => {
  const res = await fetch(`${baseUrl}/api/v1/admin/users/${pendingDriverUser._id}/verify`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      status: 'rejected',
      reason: 'License photo was blurry and unreadable.',
    }),
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.user.isVerified, false);
  assert.strictEqual(data.data.user.onboardingStatus, 'rejected');
  assert.strictEqual(data.data.user.rejectionReason, 'License photo was blurry and unreadable.');
});

test('7. Admin retrieves rides for moderation and cancels a flagged ride', async () => {
  // Fetch rides
  const listRes = await fetch(`${baseUrl}/api/v1/admin/rides?status=scheduled`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
  });
  assert.strictEqual(listRes.status, 200);
  const listData = await listRes.json();
  assert.strictEqual(listData.success, true);
  assert.ok(listData.data.rides.length >= 1);

  // Moderate/cancel ride
  const cancelRes = await fetch(`${baseUrl}/api/v1/admin/rides/${testRide._id}/moderate`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      action: 'cancel',
      reason: 'Route overlaps with highway maintenance closure.',
    }),
  });
  const cancelData = await cancelRes.json();
  if (cancelRes.status !== 200) {
    console.error('CANCEL RES ERROR:', cancelData);
  }
  assert.strictEqual(cancelRes.status, 200);
  assert.strictEqual(cancelData.success, true);
  assert.strictEqual(cancelData.data.ride.status, 'cancelled');
});

test('8. Admin retrieves safety reports and resolves an open incident', async () => {
  // Fetch reports
  const listRes = await fetch(`${baseUrl}/api/v1/admin/reports?status=open`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
  });
  assert.strictEqual(listRes.status, 200);
  const listData = await listRes.json();
  assert.strictEqual(listData.success, true);
  assert.ok(listData.data.reports.length >= 1);
  assert.strictEqual(listData.data.reports[0].title, 'Speeding on NE1 Corridor');

  // Resolve report
  const resolveRes = await fetch(`${baseUrl}/api/v1/admin/reports/${testReport._id}/resolve`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      status: 'resolved',
      notes: 'Driver was counseled regarding speed compliance; warning issued.',
    }),
  });
  assert.strictEqual(resolveRes.status, 200);
  const resolveData = await resolveRes.json();
  assert.strictEqual(resolveData.success, true);
  assert.strictEqual(resolveData.data.report.status, 'resolved');
  assert.strictEqual(resolveData.data.report.resolutionNotes, 'Driver was counseled regarding speed compliance; warning issued.');
});
