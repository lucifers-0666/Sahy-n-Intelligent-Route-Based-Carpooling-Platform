const test = require('node:test');
const assert = require('node:assert');
const crypto = require('crypto');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');
const PaymentTransaction = require('../src/models/PaymentTransaction');
const AuditLog = require('../src/models/AuditLog');
const FraudDetectionService = require('../src/services/fraudDetectionService');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let driverUser;
let driverToken;
let driverVehicle;

let passengerUser;
let passengerToken;

let secondPassengerUser;
let secondPassengerToken;

let adminUser;
let adminToken;

let testRide;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_test';
    await mongoose.connect(mongoUri);
  }

  await Booking.init();
  await Ride.init();
  await User.init();
  await Vehicle.init();
  await PaymentTransaction.init();
  await AuditLog.init();

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});
  await PaymentTransaction.deleteMany({});
  await AuditLog.deleteMany({});

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  // 1. Driver setup
  driverUser = await User.create({
    name: 'Harsh Driver',
    email: 'harsh.driver@example.com',
    phone: '+919876540001',
    password: 'Password@123',
    role: 'user',
    isVerified: true,
    capabilities: { canRide: true, canDrive: true, canBookCash: true },
    driverProfile: {
      onboardingStatus: 'approved',
      licenseNumber: 'GJ0120200001',
      licenseExpiryDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // Valid for 1 year
    },
  });
  driverToken = jwt.sign(
    { id: driverUser._id.toString(), email: driverUser.email, role: 'user' },
    getJwtSecret(),
    { expiresIn: '1h' }
  );

  // 2. Driver Vehicle
  driverVehicle = await Vehicle.create({
    owner: driverUser._id,
    registrationNumber: 'GJ01FP1111',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'White',
    seatCapacity: 4,
    status: 'active',
  });

  // 3. Passenger 1 setup
  passengerUser = await User.create({
    name: 'Aarav Passenger',
    email: 'aarav.passenger@example.com',
    phone: '+919876540002',
    password: 'Password@123',
    role: 'user',
    isVerified: true,
    capabilities: { canRide: true, canDrive: false, canBookCash: true },
  });
  passengerToken = jwt.sign(
    { id: passengerUser._id.toString(), email: passengerUser.email, role: 'user' },
    getJwtSecret(),
    { expiresIn: '1h' }
  );

  // 4. Passenger 2 setup
  secondPassengerUser = await User.create({
    name: 'Priya Passenger',
    email: 'priya.passenger@example.com',
    phone: '+919876540003',
    password: 'Password@123',
    role: 'user',
    isVerified: true,
    capabilities: { canRide: true, canDrive: false, canBookCash: true },
  });
  secondPassengerToken = jwt.sign(
    { id: secondPassengerUser._id.toString(), email: secondPassengerUser.email, role: 'user' },
    getJwtSecret(),
    { expiresIn: '1h' }
  );

  // 5. Admin setup
  adminUser = await User.create({
    name: 'Platform Admin',
    email: 'admin.fraud@example.com',
    phone: '+919876540099',
    password: 'Password@123',
    role: 'super_admin',
    isVerified: true,
  });
  adminToken = jwt.sign(
    { id: adminUser._id.toString(), email: adminUser.email, role: 'super_admin' },
    getJwtSecret(),
    { expiresIn: '1h' }
  );

  // 6. Test Ride
  testRide = await Ride.create({
    driver: driverUser._id,
    vehicle: driverVehicle._id,
    origin: {
      name: 'Ahmedabad Iscon',
      latitude: 23.0276,
      longitude: 72.5076,
      point: { type: 'Point', coordinates: [72.5076, 23.0276] },
    },
    destination: {
      name: 'Vadodara Alkapuri',
      latitude: 22.3072,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    route: {
      encodedPolyline: 'u~_bA_~_bA',
      distanceMeters: 110000,
      durationSeconds: 7200,
    },
    departureTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
    estimatedArrivalTime: new Date(Date.now() + 4 * 60 * 60 * 1000),
    availableSeats: 3,
    totalSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 250,
    cancellationPolicy: {
      policyType: 'moderate',
      description: 'Free cancellation up to 2 hours before scheduled departure.',
    },
    allowedPaymentMethods: ['cash', 'upi', 'card', 'netbanking', 'sandbox'],
    status: 'scheduled',
  });
});

test.after(async () => {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});

test.describe('Sahyān Trust, Fraud Prevention & Payment Integrity Suite', () => {

  test('P0: Atomic booking creation with policy snapshot & idempotency support', async () => {
    const idempotencyKey = 'idemp_key_unique_001';

    // First request creates booking
    const res1 = await fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        rideId: testRide._id.toString(),
        requestedSeats: 1,
        paymentMethod: 'cash',
        idempotencyKey,
      }),
    });

    const data1 = await res1.json();
    assert.strictEqual(res1.status, 201);
    assert.strictEqual(data1.success, true);
    assert.strictEqual(data1.data.status, 'pending');
    assert.strictEqual(data1.data.paymentMethod, 'cash');
    assert.strictEqual(data1.data.paymentType, 'cash_on_boarding');
    assert.strictEqual(data1.data.cancellationPolicy.policyType, 'moderate');

    const createdBookingId = data1.data.id || data1.data._id;

    // Second request with same idempotency key returns existing booking without duplicating
    const res2 = await fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        rideId: testRide._id.toString(),
        requestedSeats: 1,
        paymentMethod: 'cash',
        idempotencyKey,
      }),
    });

    const data2 = await res2.json();
    assert.strictEqual(res2.status, 200);
    assert.strictEqual(data2.data.id || data2.data._id, createdBookingId);
  });

  test('P0: Accepting booking issues cryptographic 4-digit Boarding PIN', async () => {
    // Passenger creates booking
    const createRes = await fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${secondPassengerToken}`,
      },
      body: JSON.stringify({
        rideId: testRide._id.toString(),
        requestedSeats: 1,
        paymentMethod: 'cash',
      }),
    });
    const createData = await createRes.json();
    const bookingId = createData.data.id || createData.data._id;

    // Driver accepts booking
    const acceptRes = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${driverToken}`,
      },
    });
    const acceptData = await acceptRes.json();
    assert.strictEqual(acceptRes.status, 200);
    assert.strictEqual(acceptData.data.status, 'accepted');

    // Verify server-side Boarding PIN generated in MongoDB
    const bookingInDb = await Booking.findById(bookingId);
    assert.ok(bookingInDb.boardingPin, 'Boarding PIN must be generated on accept');
    assert.match(bookingInDb.boardingPin, /^[0-9]{4}$/, 'Boarding PIN must be 4 digits');
    assert.strictEqual(bookingInDb.boardingPinLocked, false);
    assert.strictEqual(bookingInDb.boardingPinAttempts, 0);
  });

  test('P0: Boarding PIN verification rejects unauthorized caller and invalid PIN', async () => {
    const activeBooking = await Booking.findOne({
      passenger: secondPassengerUser._id,
      status: 'accepted',
    });
    assert.ok(activeBooking);

    // 1. Unauthorized caller (Passenger cannot verify their own PIN)
    const unauthRes = await fetch(`${baseUrl}/bookings/${activeBooking._id}/verify-pin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({ pin: activeBooking.boardingPin }),
    });
    assert.strictEqual(unauthRes.status, 403);

    // 2. Driver attempts invalid PIN format
    const invalidFormatRes = await fetch(`${baseUrl}/bookings/${activeBooking._id}/verify-pin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverToken}`,
      },
      body: JSON.stringify({ pin: '12' }),
    });
    assert.strictEqual(invalidFormatRes.status, 400);

    // 3. Driver submits incorrect 4-digit PIN
    const wrongPinRes = await fetch(`${baseUrl}/bookings/${activeBooking._id}/verify-pin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverToken}`,
      },
      body: JSON.stringify({ pin: '0000' }),
    });
    const wrongData = await wrongPinRes.json();
    assert.strictEqual(wrongPinRes.status, 400);
    assert.ok(wrongData.message.includes('Remaining attempts'));
  });

  test('P0: Boarding PIN locks after 5 consecutive failed attempts', async () => {
    const booking = await Booking.findOne({
      passenger: secondPassengerUser._id,
      status: 'accepted',
    });
    assert.ok(booking);

    // Send remaining incorrect attempts until 5
    for (let i = 2; i <= 5; i++) {
      await fetch(`${baseUrl}/bookings/${booking._id}/verify-pin`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${driverToken}`,
        },
        body: JSON.stringify({ pin: '9999' }),
      });
    }

    // Verify booking is now locked in DB
    const lockedBooking = await Booking.findById(booking._id);
    assert.strictEqual(lockedBooking.boardingPinLocked, true);
    assert.strictEqual(lockedBooking.boardingPinAttempts, 5);

    // Any further attempt is rejected with 403
    const lockedRes = await fetch(`${baseUrl}/bookings/${booking._id}/verify-pin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverToken}`,
      },
      body: JSON.stringify({ pin: lockedBooking.boardingPin }),
    });
    assert.strictEqual(lockedRes.status, 403);
  });

  test('P0: Correct Boarding PIN marks passenger boarded and logs audit trail', async () => {
    // Reset PIN for valid boarding test
    const booking = await Booking.findOne({
      passenger: secondPassengerUser._id,
      status: 'accepted',
    });
    booking.boardingPinLocked = false;
    booking.boardingPinAttempts = 0;
    booking.boardingPin = '7890';
    await booking.save();

    const verifyRes = await fetch(`${baseUrl}/bookings/${booking._id}/verify-pin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverToken}`,
      },
      body: JSON.stringify({ pin: '7890' }),
    });

    const verifyData = await verifyRes.json();
    assert.strictEqual(verifyRes.status, 200);
    assert.strictEqual(verifyData.success, true);
    assert.ok(verifyData.data.boardedAt);

    // Verify AuditLog record
    const auditRecord = await AuditLog.findOne({
      action: 'BOARDING_PIN_VERIFIED',
      bookingId: booking._id,
    });
    assert.ok(auditRecord, 'AuditLog entry must be recorded for BOARDING_PIN_VERIFIED');
  });

  test('P1: Cash payment confirmation & non-payment dispute workflow', async () => {
    const booking = await Booking.findOne({
      passenger: secondPassengerUser._id,
      status: 'accepted',
    });

    // 1. Driver reports non-payment
    const reportRes = await fetch(`${baseUrl}/bookings/${booking._id}/report-unpaid`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverToken}`,
      },
      body: JSON.stringify({ notes: 'Passenger did not have cash at drop location' }),
    });
    const reportData = await reportRes.json();
    assert.strictEqual(reportRes.status, 200);
    assert.strictEqual(reportData.data.paymentStatus, 'unpaid_reported');
    assert.strictEqual(reportData.data.dispute.status, 'unpaid_reported');

    // 2. Passenger files dispute response
    const disputeRes = await fetch(`${baseUrl}/bookings/${booking._id}/dispute-unpaid`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${secondPassengerToken}`,
      },
      body: JSON.stringify({
        notes: 'Handed over cash of Rs. 250 at departure point',
        evidenceUrls: ['https://example.com/receipt.png'],
      }),
    });
    const disputeData = await disputeRes.json();
    assert.strictEqual(disputeRes.status, 200);
    assert.strictEqual(disputeData.data.paymentStatus, 'disputed');
    assert.strictEqual(disputeData.data.dispute.status, 'passenger_disputed');
  });

  test('P1: Admin dispute case investigation & resolution workflow', async () => {
    const booking = await Booking.findOne({
      passenger: secondPassengerUser._id,
      'dispute.status': 'passenger_disputed',
    });
    assert.ok(booking);

    // 1. Admin queries dispute cases
    const listRes = await fetch(`${baseUrl}/admin/disputes`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    const listData = await listRes.json();
    assert.strictEqual(listRes.status, 200);
    assert.ok(listData.count >= 1);

    // 2. Admin resolves dispute with penalty on passenger
    const resolveRes = await fetch(`${baseUrl}/admin/disputes/${booking._id}/resolve`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        resolution: 'penalty_applied',
        notes: 'Driver confirmed trip completion, passenger cashless without notice',
      }),
    });
    const resolveData = await resolveRes.json();
    assert.strictEqual(resolveRes.status, 200);
    assert.strictEqual(resolveData.data.dispute.status, 'penalty_applied');

    // Verify passenger capabilities restricted
    const updatedPassenger = await User.findById(booking.passenger);
    assert.strictEqual(updatedPassenger.capabilities.canBookCash, false);

    // Verify AuditLog
    const auditDispute = await AuditLog.findOne({
      action: 'DISPUTE_RESOLVED',
      bookingId: booking._id,
    });
    assert.ok(auditDispute);
  });

  test('P2: Restricted passenger cannot book new ride using cash', async () => {
    const res = await fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${secondPassengerToken}`,
      },
      body: JSON.stringify({
        rideId: testRide._id.toString(),
        requestedSeats: 1,
        paymentMethod: 'cash',
      }),
    });
    const data = await res.json();
    assert.strictEqual(res.status, 403);
    assert.ok(data.message.includes('Cash payment is restricted'));
  });

  test('P2: User appeal review and reinstatement by admin', async () => {
    // Passenger submits appeal
    const passenger = await User.findById(secondPassengerUser._id);
    passenger.appeals.push({
      reason: 'I have settled with the driver via direct UPI transfer.',
      status: 'pending',
    });
    await passenger.save();

    // Admin fetches appeals
    const appealsRes = await fetch(`${baseUrl}/admin/appeals`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    const appealsData = await appealsRes.json();
    assert.strictEqual(appealsRes.status, 200);
    assert.ok(appealsData.count >= 1);

    // Admin approves appeal
    const reviewRes = await fetch(
      `${baseUrl}/admin/appeals/${passenger._id.toString()}/0`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          action: 'approve',
          reviewerNotes: 'Reinstated after verifying direct UPI payment proof',
        }),
      }
    );
    const reviewData = await reviewRes.json();
    assert.strictEqual(reviewRes.status, 200);

    const reinstatedUser = await User.findById(passenger._id);
    assert.strictEqual(reinstatedUser.capabilities.canBookCash, true);
    assert.strictEqual(reinstatedUser.accountStatus, 'active');
  });

  test('P3: Authoritative payment gateway webhook with HMAC verification & deduplication', async () => {
    // 1. Create a payment transaction
    const tx = await PaymentTransaction.create({
      bookingId: new mongoose.Types.ObjectId(),
      passengerId: passengerUser._id,
      driverId: driverUser._id,
      amount: 310,
      platformFee: 20,
      paymentMethod: 'upi',
      status: 'pending',
    });

    const webhookSecret = process.env.PAYMENT_WEBHOOK_SECRET || 'sahyan_webhook_secret_key';
    const eventId = 'evt_razorpay_998877';

    const payload = {
      eventId,
      transactionId: tx._id.toString(),
      amount: 310,
      status: 'captured',
    };
    const payloadStr = JSON.stringify(payload);
    const signature = crypto.createHmac('sha256', webhookSecret).update(payloadStr).digest('hex');

    // 2. Reject invalid signature
    const invalidSigRes = await fetch(`${baseUrl}/payments/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-payment-signature': 'invalid_signature_hex_value_000000',
      },
      body: payloadStr,
    });
    assert.strictEqual(invalidSigRes.status, 401);

    // 3. Accept valid HMAC signature
    const validRes = await fetch(`${baseUrl}/payments/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-payment-signature': signature,
      },
      body: payloadStr,
    });
    const validData = await validRes.json();
    assert.strictEqual(validRes.status, 200);
    assert.strictEqual(validData.success, true);

    const updatedTx = await PaymentTransaction.findById(tx._id);
    assert.strictEqual(updatedTx.status, 'escrow_held');
    assert.strictEqual(updatedTx.verifiedBy, 'provider_webhook');
    assert.strictEqual(updatedTx.webhookEventId, eventId);

    // 4. Deduplication: Send identical webhook event again
    const dupRes = await fetch(`${baseUrl}/payments/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-payment-signature': signature,
      },
      body: payloadStr,
    });
    const dupData = await dupRes.json();
    assert.strictEqual(dupRes.status, 200);
    assert.ok(dupData.message.includes('Deduplicated'));
  });

  test('P2: FraudDetectionService calculates multi-factor risk scores and flags anomalies', async () => {
    // Generate risk evaluation for passenger
    const risk = await FraudDetectionService.evaluateUserRisk(secondPassengerUser._id);
    assert.ok(typeof risk.riskScore === 'number');
    assert.ok(['low', 'medium', 'high', 'critical'].includes(risk.riskTier));

    // Check collusion detection
    const collusion = await FraudDetectionService.detectCollusion(
      driverUser._id,
      passengerUser._id
    );
    assert.strictEqual(collusion.suspicious, false);

    // Check self-collusion
    const selfCollusion = await FraudDetectionService.detectCollusion(
      driverUser._id,
      driverUser._id
    );
    assert.strictEqual(selfCollusion.suspicious, true);
  });
});
