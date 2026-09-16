const test = require('node:test');
const assert = require('node:assert');
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
let driverVehicle;

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
  } catch (err) {
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

  // 1. Driver
  driverUser = await User.create({
    name: 'Vikram Driver',
    email: 'vikram.driver@example.com',
    phone: '+919876543210',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  driverToken = jwt.sign({ id: driverUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // 2. Passenger
  passengerUser = await User.create({
    name: 'Priya Passenger',
    email: 'priya.passenger@example.com',
    phone: '+919876543211',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // 3. Unauthorized User
  unauthorizedUser = await User.create({
    name: 'Sneha Other',
    email: 'sneha.other@example.com',
    phone: '+919876543212',
    password: 'Password123@#',
    city: 'Vadodara',
    isVerified: true,
  });
  unauthorizedToken = jwt.sign({ id: unauthorizedUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // 4. Vehicle
  driverVehicle = await Vehicle.create({
    owner: driverUser._id,
    make: 'Hyundai',
    model: 'Creta',
    registrationNumber: 'GJ01AB9999',
    seatCapacity: 4,
    year: 2022,
    vehicleType: 'suv',
    color: 'White',
  });

  // 5. Ride
  const departureDate = new Date(Date.now() + 24 * 3600 * 1000);
  const arrivalDate = new Date(departureDate.getTime() + 4 * 3600 * 1000);

  testRide = await Ride.create({
    driver: driverUser._id,
    vehicle: driverVehicle._id,
    origin: {
      name: 'Ahmedabad Airport',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    destination: {
      name: 'Rajkot Bus Stand',
      latitude: 22.3039,
      longitude: 70.8022,
      point: { type: 'Point', coordinates: [70.8022, 22.3039] },
    },
    route: {
      encodedPolyline: 'u{~nE_w~vOu`@z_@',
      distanceMeters: 215000,
      durationSeconds: 14400,
    },
    departureTime: departureDate,
    estimatedArrivalTime: arrivalDate,
    totalSeats: 3,
    availableSeats: 2,
    bookedSeats: 1,
    contributionPerSeat: 350,
    status: 'scheduled',
  });

  // 6. Booking
  testBooking = await Booking.create({
    ride: testRide._id,
    passenger: passengerUser._id,
    requestedSeats: 1,
    contributionPerSeat: 350,
    totalContribution: 350,
    pickup: {
      name: 'Ahmedabad Airport',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    drop: {
      name: 'Rajkot Bus Stand',
      latitude: 22.3039,
      longitude: 70.8022,
      point: { type: 'Point', coordinates: [70.8022, 22.3039] },
    },
    status: 'accepted',
    paymentStatus: 'pending',
  });
});

test.after(async () => {
  if (server) server.close();
  if (mongoose.connection && mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }
  if (mongoServer) await mongoServer.stop();
});

test('1. Unauthenticated request to /payments/order is rejected with 401', async () => {
  const res = await fetch(`${baseUrl}/payments/order`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ bookingId: testBooking._id }),
  });
  assert.strictEqual(res.status, 401);
});

test('2. Unauthorized user cannot create order for someone else booking (403)', async () => {
  const res = await fetch(`${baseUrl}/payments/order`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${unauthorizedToken}`,
    },
    body: JSON.stringify({ bookingId: testBooking._id }),
  });
  assert.strictEqual(res.status, 403);
});

let createdTransactionId;

test('3. Passenger successfully creates payment order with correct fee split (201)', async () => {
  const res = await fetch(`${baseUrl}/payments/order`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({ bookingId: testBooking._id }),
  });

  assert.strictEqual(res.status, 201);
  const data = await res.json();
  assert.ok(data.transaction);
  assert.strictEqual(data.breakdown.baseFare, 350);
  assert.strictEqual(data.breakdown.platformFee, 20);
  assert.strictEqual(data.breakdown.tollSplit, 40);
  assert.strictEqual(data.breakdown.total, 410);
  assert.strictEqual(data.transaction.status, 'pending');

  createdTransactionId = data.transaction._id;
});

test('4. Passenger verifies payment authorization -> moves to escrow_held (200)', async () => {
  const res = await fetch(`${baseUrl}/payments/verify`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      transactionId: createdTransactionId,
      gatewayReference: 'mock_pay_123456',
      method: 'upi_mock',
    }),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.transaction.status, 'escrow_held');
  assert.strictEqual(data.booking.paymentStatus, 'paid');
});

test('5. Trying to create order on already paid booking is rejected with 400', async () => {
  const res = await fetch(`${baseUrl}/payments/order`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({ bookingId: testBooking._id }),
  });

  assert.strictEqual(res.status, 400);
});

test('6. Trip completion releases escrow funds to driver', async () => {
  // Move ride: scheduled -> boarding -> active -> completed
  testRide.status = 'active';
  await testRide.save();

  const completeRes = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });

  assert.strictEqual(completeRes.status, 200);

  // Check transaction status
  const tx = await PaymentTransaction.findById(createdTransactionId);
  assert.strictEqual(tx.status, 'settled_to_driver');

  // Check booking status
  const b = await Booking.findById(testBooking._id);
  assert.strictEqual(b.paymentStatus, 'escrow_released');
});
