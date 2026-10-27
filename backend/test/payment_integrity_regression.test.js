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
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let driverUser;
let driverToken;
let passengerUser;
let passengerToken;
let unauthorizedUser;
let unauthorizedToken;

let testRide;
let testBooking;

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
  await PaymentTransaction.init();

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});
  await PaymentTransaction.deleteMany({});

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  driverUser = await User.create({
    name: 'Karan Driver',
    email: 'karan.driver@example.com',
    phone: '+919811111111',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  driverToken = jwt.sign({ id: driverUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  passengerUser = await User.create({
    name: 'Meera Passenger',
    email: 'meera.passenger@example.com',
    phone: '+919822222222',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  unauthorizedUser = await User.create({
    name: 'Rohan Other',
    email: 'rohan.other@example.com',
    phone: '+919833333333',
    password: 'Password123@#',
    city: 'Surat',
    isVerified: true,
  });
  unauthorizedToken = jwt.sign({ id: unauthorizedUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  const vehicle = await Vehicle.create({
    owner: driverUser._id,
    make: 'Maruti',
    model: 'Ertiga',
    registrationNumber: 'GJ01CD1234',
    seatCapacity: 6,
    year: 2023,
    vehicleType: 'suv',
    color: 'Silver',
  });

  const departureDate = new Date(Date.now() + 24 * 3600 * 1000);
  const arrivalDate = new Date(departureDate.getTime() + 3 * 3600 * 1000);

  testRide = await Ride.create({
    driver: driverUser._id,
    vehicle: vehicle._id,
    origin: {
      name: 'Ahmedabad ISKCON',
      latitude: 23.0298,
      longitude: 72.5074,
      point: { type: 'Point', coordinates: [72.5074, 23.0298] },
    },
    destination: {
      name: 'Vadodara Central',
      latitude: 22.3072,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    route: {
      encodedPolyline: 'g}weD_qhyM~@_@b@_@|@e@',
      distanceMeters: 110000,
      durationSeconds: 7200,
    },
    departureTime: departureDate,
    estimatedArrivalTime: arrivalDate,
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 1,
    contributionPerSeat: 250,
    status: 'scheduled',
  });

  testBooking = await Booking.create({
    ride: testRide._id,
    passenger: passengerUser._id,
    requestedSeats: 1,
    contributionPerSeat: 250,
    totalContribution: 250,
    pickup: {
      name: 'Ahmedabad ISKCON',
      latitude: 23.0298,
      longitude: 72.5074,
      point: { type: 'Point', coordinates: [72.5074, 23.0298] },
    },
    drop: {
      name: 'Vadodara Central',
      latitude: 22.3072,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    status: 'accepted',
    paymentStatus: 'pending',
    paymentType: 'online_escrow',
    paymentMethod: 'sandbox',
    boardingPin: '1234',
  });
});

test.after(async () => {
  if (server) server.close();
  await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
});

test('1. Payment order creation enforces sandbox mode when gateway credentials absent', async () => {
  const res = await fetch(`${baseUrl}/payments/order`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      bookingId: testBooking._id.toString(),
      paymentMethod: 'sandbox',
    }),
  });

  assert.strictEqual(res.status, 201);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.order.isSandbox, true);
  assert.ok(data.order.orderId.startsWith('sandbox_ord_'));
  assert.strictEqual(data.transaction.currency, 'INR');
  assert.strictEqual(data.transaction.amount, 310); // 250 + 20 fee + 40 toll
});

test('2. Verification rejects forged cryptographic signature in production gateway mode', async () => {
  const oldSecret = process.env.RAZORPAY_KEY_SECRET;
  const oldEnv = process.env.NODE_ENV;
  process.env.RAZORPAY_KEY_SECRET = 'live_secret_key_12345';
  process.env.RAZORPAY_KEY_ID = 'rzp_live_12345';
  process.env.NODE_ENV = 'production';

  try {
    // Create a live transaction record
    const liveTx = await PaymentTransaction.create({
      bookingId: testBooking._id,
      passengerId: passengerUser._id,
      driverId: driverUser._id,
      amount: 310,
      platformFee: 20,
      paymentMethod: 'card',
      isSandbox: false,
      gatewayOrderId: 'order_live_99999',
      status: 'pending',
    });

    const res = await fetch(`${baseUrl}/payments/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        transactionId: liveTx._id.toString(),
        razorpay_order_id: 'order_live_99999',
        razorpay_payment_id: 'pay_live_forged_ref',
        razorpay_signature: 'fake_cryptographic_signature_value',
      }),
    });

    assert.strictEqual(res.status, 401);
    const data = await res.json();
    assert.strictEqual(data.success, false);
    assert.strictEqual(data.error, 'Invalid payment signature');

    const txCheck = await PaymentTransaction.findById(liveTx._id);
    assert.strictEqual(txCheck.status, 'pending');
  } finally {
    process.env.RAZORPAY_KEY_SECRET = oldSecret;
    process.env.NODE_ENV = oldEnv;
  }
});

test('3. Verification is strictly idempotent and prevents duplicate state changes', async () => {
  const sandboxTx = await PaymentTransaction.create({
    bookingId: testBooking._id,
    passengerId: passengerUser._id,
    driverId: driverUser._id,
    amount: 310,
    platformFee: 20,
    paymentMethod: 'upi',
    isSandbox: true,
    status: 'pending',
  });

  // First verification
  const res1 = await fetch(`${baseUrl}/payments/verify`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      transactionId: sandboxTx._id.toString(),
      method: 'upi',
    }),
  });

  assert.strictEqual(res1.status, 200);
  const data1 = await res1.json();
  assert.strictEqual(data1.success, true);
  assert.strictEqual(data1.transaction.status, 'escrow_held');

  // Second duplicate verification (idempotent replay)
  const res2 = await fetch(`${baseUrl}/payments/verify`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      transactionId: sandboxTx._id.toString(),
      method: 'upi',
    }),
  });

  assert.strictEqual(res2.status, 200);
  const data2 = await res2.json();
  assert.strictEqual(data2.success, true);
  assert.ok(data2.message.includes('Idempotent'));
});

test('4. Webhook rejects invalid HMAC signatures and protects against duplicate events', async () => {
  const webhookSecret = 'test_webhook_secret_key_999';
  const oldWebhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  process.env.RAZORPAY_WEBHOOK_SECRET = webhookSecret;

  try {
    const webhookTx = await PaymentTransaction.create({
      bookingId: testBooking._id,
      passengerId: passengerUser._id,
      driverId: driverUser._id,
      amount: 310,
      platformFee: 20,
      paymentMethod: 'card',
      isSandbox: true,
      status: 'pending',
    });

    const payload = JSON.stringify({
      eventId: 'evt_unique_1001',
      transactionId: webhookTx._id.toString(),
      amount: 310,
      currency: 'INR',
    });

    // 1. Forged signature rejected
    const forgedRes = await fetch(`${baseUrl}/payments/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-razorpay-signature': 'bad_forged_sig',
      },
      body: payload,
    });
    assert.strictEqual(forgedRes.status, 401);

    // 2. Valid signature accepted
    const validSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(payload)
      .digest('hex');

    const validRes1 = await fetch(`${baseUrl}/payments/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-razorpay-signature': validSignature,
        'x-razorpay-event-id': 'evt_unique_1001',
      },
      body: payload,
    });
    assert.strictEqual(validRes1.status, 200);
    const validData1 = await validRes1.json();
    assert.strictEqual(validData1.success, true);

    // 3. Duplicate event ID rejected with duplicate status
    const validRes2 = await fetch(`${baseUrl}/payments/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-razorpay-signature': validSignature,
        'x-razorpay-event-id': 'evt_unique_1001',
      },
      body: payload,
    });
    assert.strictEqual(validRes2.status, 200);
    const validData2 = await validRes2.json();
    assert.strictEqual(validData2.duplicate, true);
  } finally {
    process.env.RAZORPAY_WEBHOOK_SECRET = oldWebhookSecret;
  }
});

test('5. Safe refund workflow executes for escrow_held booking and prevents double-refund', async () => {
  const refundPassengerUser = await User.create({
    name: 'Refund Passenger',
    email: 'refund.passenger@example.com',
    phone: '+919844444444',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  const refundPassengerToken = jwt.sign(
    { id: refundPassengerUser._id.toString() },
    getJwtSecret(),
    { expiresIn: '1h' }
  );

  // Create a separate booking with escrow_held transaction
  const refundBooking = await Booking.create({
    ride: testRide._id,
    passenger: refundPassengerUser._id,
    requestedSeats: 1,
    contributionPerSeat: 250,
    totalContribution: 250,
    pickup: {
      name: 'Ahmedabad ISKCON',
      latitude: 23.0298,
      longitude: 72.5074,
      point: { type: 'Point', coordinates: [72.5074, 23.0298] },
    },
    drop: {
      name: 'Vadodara Central',
      latitude: 22.3072,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    status: 'accepted',
    paymentStatus: 'paid',
    paymentType: 'online_escrow',
    paymentMethod: 'upi',
  });

  const refundTx = await PaymentTransaction.create({
    bookingId: refundBooking._id,
    passengerId: refundPassengerUser._id,
    driverId: driverUser._id,
    amount: 310,
    platformFee: 20,
    paymentMethod: 'upi',
    isSandbox: true,
    status: 'escrow_held',
  });

  refundBooking.paymentTransactionId = refundTx._id;
  await refundBooking.save();

  // Unauthorized user cannot refund
  const unauthRes = await fetch(`${baseUrl}/payments/refund`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${unauthorizedToken}`,
    },
    body: JSON.stringify({
      bookingId: refundBooking._id.toString(),
      reason: 'Unauthorized refund attempt',
    }),
  });
  assert.strictEqual(unauthRes.status, 403);

  // Authorized passenger executes refund
  const refundRes = await fetch(`${baseUrl}/payments/refund`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${refundPassengerToken}`,
    },
    body: JSON.stringify({
      bookingId: refundBooking._id.toString(),
      reason: 'Passenger travel plan altered before departure',
    }),
  });

  assert.strictEqual(refundRes.status, 200);
  const refundData = await refundRes.json();
  assert.strictEqual(refundData.success, true);
  assert.strictEqual(refundData.transaction.status, 'refunded');

  const refreshedBooking = await Booking.findById(refundBooking._id);
  assert.strictEqual(refreshedBooking.paymentStatus, 'refunded');

  // Double refund attempt returns idempotent response
  const doubleRefundRes = await fetch(`${baseUrl}/payments/refund`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${refundPassengerToken}`,
    },
    body: JSON.stringify({
      bookingId: refundBooking._id.toString(),
      reason: 'Second attempt should be idempotent',
    }),
  });
  assert.strictEqual(doubleRefundRes.status, 200);
  const doubleData = await doubleRefundRes.json();
  assert.ok(doubleData.message.includes('already refunded'));
});

test('6. Payment reconciliation returns comprehensive financial audit state', async () => {
  const reconRes = await fetch(`${baseUrl}/payments/reconcile/${testBooking._id}`, {
    headers: {
      Authorization: `Bearer ${passengerToken}`,
    },
  });

  assert.strictEqual(reconRes.status, 200);
  const reconData = await reconRes.json();
  assert.strictEqual(reconData.success, true);
  assert.strictEqual(reconData.reconciliation.bookingId, testBooking._id.toString());
  assert.ok(Array.isArray(reconData.reconciliation.transactions));
  assert.strictEqual(typeof reconData.reconciliation.reconciled, 'boolean');
});
