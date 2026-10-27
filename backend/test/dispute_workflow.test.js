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
const PaymentTransaction = require('../src/models/PaymentTransaction');
const AuditLog = require('../src/models/AuditLog');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let adminUser;
let adminToken;
let driverUser;
let driverToken;
let passengerUser;
let passengerToken;
let otherUser;
let otherToken;

let testRide;
let testBooking;
let testTx;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (_) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_test';
    await mongoose.connect(mongoUri);
  }

  await Booking.init();
  await Ride.init();
  await User.init();
  await Vehicle.init();
  await Report.init();
  await PaymentTransaction.init();
  await AuditLog.init();

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});
  await Report.deleteMany({});
  await PaymentTransaction.deleteMany({});
  await AuditLog.deleteMany({});

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  adminUser = await User.create({
    name: 'Super Admin',
    email: 'admin@sahyan.com',
    phone: '+919999900001',
    password: 'Password123@#',
    role: 'super_admin',
    isVerified: true,
  });
  adminToken = jwt.sign({ id: adminUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  driverUser = await User.create({
    name: 'Dilip Driver',
    email: 'dilip.driver@example.com',
    phone: '+919877700001',
    password: 'Password123@#',
    city: 'Surat',
    isVerified: true,
  });
  driverToken = jwt.sign({ id: driverUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  passengerUser = await User.create({
    name: 'Pooja Passenger',
    email: 'pooja.passenger@example.com',
    phone: '+919877700002',
    password: 'Password123@#',
    city: 'Surat',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  otherUser = await User.create({
    name: 'Bhavin Bystander',
    email: 'bhavin.bystander@example.com',
    phone: '+919877700003',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  otherToken = jwt.sign({ id: otherUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  const vehicle = await Vehicle.create({
    owner: driverUser._id,
    make: 'Tata',
    model: 'Nexon',
    registrationNumber: 'GJ05XY1234',
    seatCapacity: 4,
    year: 2023,
    vehicleType: 'suv',
    color: 'Blue',
  });

  const departureDate = new Date(Date.now() + 2 * 3600 * 1000);
  const arrivalDate = new Date(departureDate.getTime() + 2 * 3600 * 1000);

  testRide = await Ride.create({
    driver: driverUser._id,
    vehicle: vehicle._id,
    origin: {
      name: 'Surat Station',
      latitude: 21.1702,
      longitude: 72.8311,
      point: { type: 'Point', coordinates: [72.8311, 21.1702] },
    },
    destination: {
      name: 'Navsari Bus Station',
      latitude: 20.9467,
      longitude: 72.952,
      point: { type: 'Point', coordinates: [72.952, 20.9467] },
    },
    route: {
      encodedPolyline: 'g}weD_qhyM~@_@b@_@|@e@',
      distanceMeters: 35000,
      durationSeconds: 3600,
    },
    departureTime: departureDate,
    estimatedArrivalTime: arrivalDate,
    totalSeats: 3,
    availableSeats: 2,
    bookedSeats: 1,
    contributionPerSeat: 150,
    status: 'scheduled',
  });

  testBooking = await Booking.create({
    ride: testRide._id,
    passenger: passengerUser._id,
    requestedSeats: 1,
    contributionPerSeat: 150,
    totalContribution: 150,
    pickup: {
      name: 'Surat Station',
      latitude: 21.1702,
      longitude: 72.8311,
      point: { type: 'Point', coordinates: [72.8311, 21.1702] },
    },
    drop: {
      name: 'Navsari Bus Station',
      latitude: 20.9467,
      longitude: 72.952,
      point: { type: 'Point', coordinates: [72.952, 20.9467] },
    },
    status: 'accepted',
    paymentStatus: 'paid',
    paymentType: 'online_escrow',
    paymentMethod: 'upi',
    boardingPin: '5678',
  });

  testTx = await PaymentTransaction.create({
    bookingId: testBooking._id,
    passengerId: passengerUser._id,
    driverId: driverUser._id,
    amount: 210,
    platformFee: 20,
    paymentMethod: 'upi',
    isSandbox: true,
    status: 'escrow_held',
  });

  testBooking.paymentTransactionId = testTx._id;
  await testBooking.save();
});

test.after(async () => {
  if (server) server.close();
  await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
});

test('1. Unauthorized third party cannot file dispute on another users booking', async () => {
  const res = await fetch(`${baseUrl}/bookings/${testBooking._id}/dispute`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${otherToken}`,
    },
    body: JSON.stringify({
      reason: 'Unauthorized intervention',
      claimType: 'refund_request',
    }),
  });

  assert.strictEqual(res.status, 403);
});

test('2. Passenger submits formal dispute -> links to transaction and creates administrative Report case', async () => {
  const res = await fetch(`${baseUrl}/bookings/${testBooking._id}/dispute`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      reason: 'Driver requested significant unagreed detour causing 45 min delay',
      disputeType: 'service_issue',
      claimType: 'fare_adjustment',
      evidenceUrls: ['https://example.com/evidence_route_screenshot.jpg'],
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.ok(data.data.reportId);

  // Booking updated to disputed and under_review
  const refreshedBooking = await Booking.findById(testBooking._id);
  assert.strictEqual(refreshedBooking.paymentStatus, 'disputed');
  assert.strictEqual(refreshedBooking.dispute.status, 'under_review');
  assert.strictEqual(refreshedBooking.dispute.evidenceUrls.length, 1);

  // PaymentTransaction marked disputed
  const refreshedTx = await PaymentTransaction.findById(testTx._id);
  assert.strictEqual(refreshedTx.status, 'disputed');

  // Report case created
  const reportCase = await Report.findById(data.data.reportId);
  assert.ok(reportCase);
  assert.strictEqual(reportCase.type, 'payment_dispute');
  assert.strictEqual(reportCase.booking.toString(), testBooking._id.toString());
});

test('3. Admin can list disputes and resolve case with resolution notes', async () => {
  // 1. Admin gets dispute cases
  const listRes = await fetch(`${baseUrl}/admin/disputes`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
  });
  assert.strictEqual(listRes.status, 200);
  const listData = await listRes.json();
  assert.strictEqual(listData.success, true);
  assert.ok(Array.isArray(listData.data));

  // 2. Admin resolves dispute
  const resolveRes = await fetch(`${baseUrl}/admin/disputes/${testBooking._id}/resolve`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      resolution: 'resolved_forgiven',
      notes: 'Reviewed GPS trace and passenger notes. Fare adjusted as mutual courtesy.',
    }),
  });

  assert.strictEqual(resolveRes.status, 200);
  const resolveData = await resolveRes.json();
  assert.strictEqual(resolveData.success, true);

  const resolvedBooking = await Booking.findById(testBooking._id);
  assert.strictEqual(resolvedBooking.dispute.status, 'resolved_forgiven');
  assert.ok(resolvedBooking.dispute.resolvedAt);
});

test('4. Driver reports passenger no-show -> restores ride capacity safely without auto-banning', async () => {
  // Create another passenger and booking
  const noShowPassenger = await User.create({
    name: 'NoShow Passenger',
    email: 'noshow.passenger@example.com',
    phone: '+919877700099',
    password: 'Password123@#',
    city: 'Surat',
    isVerified: true,
  });

  const noShowBooking = await Booking.create({
    ride: testRide._id,
    passenger: noShowPassenger._id,
    requestedSeats: 1,
    contributionPerSeat: 150,
    totalContribution: 150,
    pickup: {
      name: 'Surat Station',
      latitude: 21.1702,
      longitude: 72.8311,
      point: { type: 'Point', coordinates: [72.8311, 21.1702] },
    },
    drop: {
      name: 'Navsari Bus Station',
      latitude: 20.9467,
      longitude: 72.952,
      point: { type: 'Point', coordinates: [72.952, 20.9467] },
    },
    status: 'accepted',
    paymentStatus: 'pending',
    paymentType: 'cash_on_boarding',
    paymentMethod: 'cash',
  });

  // Check initial seats on ride
  const initialRide = await Ride.findById(testRide._id);
  const initialAvailable = initialRide.availableSeats;

  // Driver reports passenger no-show
  const res = await fetch(`${baseUrl}/bookings/${noShowBooking._id}/no-show`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify({
      reason: 'Passenger did not arrive within 15 min waiting period at station pickup',
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);

  // Seat restored
  const updatedRide = await Ride.findById(testRide._id);
  assert.strictEqual(updatedRide.availableSeats, initialAvailable + 1);

  // Passenger is NOT automatically banned based solely on allegation
  const passengerAfter = await User.findById(noShowPassenger._id);
  assert.strictEqual(passengerAfter.accountStatus, 'active');
});

test('5. User appeal flow allows restricted user to appeal and admin to review and reinstate', async () => {
  // User with restriction
  const restrictedUser = await User.create({
    name: 'Appealing User',
    email: 'appealing.user@example.com',
    phone: '+919877700088',
    password: 'Password123@#',
    city: 'Surat',
    isVerified: true,
    accountStatus: 'suspended',
    capabilities: { canBookCash: false },
    fraudMetrics: { riskScore: 60, riskTier: 'high' },
    appeals: [
      {
        reason: 'Payment app had regional outage during departure. Bank statement uploaded as proof.',
        status: 'pending',
        submittedAt: new Date(),
      },
    ],
  });

  // Admin reviews appeal and approves reinstatement
  const res = await fetch(`${baseUrl}/admin/appeals/${restrictedUser._id}/0`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      action: 'approve',
      reviewerNotes: 'Verified bank statement. Suspension lifted and risk score adjusted.',
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);

  const reinstatedUser = await User.findById(restrictedUser._id);
  assert.strictEqual(reinstatedUser.accountStatus, 'active');
  assert.strictEqual(reinstatedUser.capabilities.canBookCash, true);
  assert.strictEqual(reinstatedUser.appeals[0].status, 'approved');
});
