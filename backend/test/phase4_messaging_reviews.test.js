const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');
const Message = require('../src/models/Message');
const Review = require('../src/models/Review');
const Notification = require('../src/models/Notification');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let driverUser;
let driverToken;
let passengerUser;
let passengerToken;
let thirdPartyUser;
let thirdPartyToken;
let testRide;
let testBooking;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_phase4_test';
    await mongoose.connect(mongoUri);
  }

  await User.init();
  await Vehicle.init();
  await Ride.init();
  await Booking.init();
  await Message.init();
  await Review.init();
  await Notification.init();

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});
  await Message.deleteMany({});
  await Review.deleteMany({});
  await Notification.deleteMany({});

  driverUser = await User.create({
    name: 'Karan Driver',
    email: 'karan.driver@example.com',
    phone: '+919876543210',
    password: 'Password123!',
    city: 'Ahmedabad',
    capabilities: { canDrive: true, canRide: true },
  });
  driverToken = jwt.sign({ id: driverUser._id, role: driverUser.role }, getJwtSecret(), { expiresIn: '1h' });

  passengerUser = await User.create({
    name: 'Priya Passenger',
    email: 'priya.passenger@example.com',
    phone: '+919812345678',
    password: 'Password123!',
    city: 'Vadodara',
    capabilities: { canDrive: false, canRide: true },
  });
  passengerToken = jwt.sign({ id: passengerUser._id, role: passengerUser.role }, getJwtSecret(), { expiresIn: '1h' });

  thirdPartyUser = await User.create({
    name: 'Rohan Stranger',
    email: 'rohan.stranger@example.com',
    phone: '+919899999999',
    password: 'Password123!',
    city: 'Surat',
    capabilities: { canDrive: false, canRide: true },
  });
  thirdPartyToken = jwt.sign({ id: thirdPartyUser._id, role: thirdPartyUser.role }, getJwtSecret(), { expiresIn: '1h' });

  const vehicle = await Vehicle.create({
    owner: driverUser._id,
    make: 'Hyundai',
    model: 'Creta',
    vehicleType: 'suv',
    registrationNumber: 'GJ-01-AB-1234',
    year: 2023,
    color: 'White',
    seatCapacity: 4,
  });

  const departure = new Date(Date.now() + 3600000);
  const arrival = new Date(Date.now() + 7200000);

  testRide = await Ride.create({
    driver: driverUser._id,
    vehicle: vehicle._id,
    origin: {
      name: 'Iscon Cross Roads, Ahmedabad',
      latitude: 23.0276,
      longitude: 72.5065,
      point: { type: 'Point', coordinates: [72.5065, 23.0276] },
    },
    destination: {
      name: 'Alkapuri, Vadodara',
      latitude: 22.3107,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3107] },
    },
    route: {
      encodedPolyline: 'u{~nE_w~vOu`@z_@',
      distanceMeters: 110000,
      durationSeconds: 5400,
    },
    departureTime: departure,
    estimatedArrivalTime: arrival,
    totalSeats: 3,
    availableSeats: 2,
    contributionPerSeat: 250,
    status: 'scheduled',
  });

  testBooking = await Booking.create({
    passenger: passengerUser._id,
    ride: testRide._id,
    requestedSeats: 1,
    contributionPerSeat: 250,
    totalContribution: 250,
    status: 'accepted',
    pickup: testRide.origin,
    drop: testRide.destination,
  });

  await new Promise((resolve) => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}`;
      resolve();
    });
  });
});

test.after(async () => {
  if (server) await new Promise((r) => server.close(r));
  await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
});

test('1. Passenger sends message to driver within booking context (201)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/messages`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      bookingId: testBooking._id.toString(),
      text: 'Hello Karan, I have reached the pickup point.',
    }),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data.text, 'Hello Karan, I have reached the pickup point.');
  assert.strictEqual(body.data.sender._id.toString(), passengerUser._id.toString());
  assert.strictEqual(body.data.receiver._id.toString(), driverUser._id.toString());
});

test('2. Unauthorized third party cannot send message in this booking (403)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/messages`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${thirdPartyToken}`,
    },
    body: JSON.stringify({
      bookingId: testBooking._id.toString(),
      text: 'Trying to snoop in this chat.',
    }),
  });

  assert.strictEqual(res.status, 403);
  const body = await res.json();
  assert.strictEqual(body.success, false);
});

test('3. Driver retrieves messages and unread messages get marked read (200)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/messages/${testBooking._id}`, {
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert(body.data.length >= 1);

  // Check read status in DB
  const unreadCount = await Message.countDocuments({
    booking: testBooking._id,
    receiver: driverUser._id,
    readAt: null,
  });
  assert.strictEqual(unreadCount, 0);
});

test('4. Driver sends reply to passenger (201)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/messages`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify({
      bookingId: testBooking._id.toString(),
      text: 'Great! Waiting in the White Creta near service lane.',
    }),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data.receiver._id.toString(), passengerUser._id.toString());
});

test('5. Conversations list returns participant details and last message (200)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/messages`, {
    headers: {
      Authorization: `Bearer ${passengerToken}`,
    },
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert(body.data.length >= 1);
  const conv = body.data[0];
  assert.strictEqual(conv.bookingId, testBooking._id.toString());
  assert.strictEqual(conv.participantName, 'Karan Driver');
  assert.strictEqual(conv.participantRole, 'Driver');
});

test('6. Passenger submits 5-star review for driver (201)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/reviews`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      bookingId: testBooking._id.toString(),
      rating: 5,
      tags: ['Punctual', 'Smooth Driving', 'Clean Vehicle'],
      comment: 'Excellent journey, very polite and on time!',
    }),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data.rating, 5);
  assert.strictEqual(body.driverRating.average, 5.0);
  assert.strictEqual(body.driverRating.count, 1);

  // Check updated user document
  const updatedDriver = await User.findById(driverUser._id);
  assert.strictEqual(updatedDriver.rating.average, 5.0);
  assert.strictEqual(updatedDriver.rating.count, 1);
});

test('7. Passenger cannot submit duplicate review for same booking (409)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/reviews`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      bookingId: testBooking._id.toString(),
      rating: 4,
      tags: ['Polite'],
      comment: 'Trying to review again.',
    }),
  });

  assert.strictEqual(res.status, 409);
  const body = await res.json();
  assert.strictEqual(body.success, false);
});

test('8. Retrieve public reviews and stats for driver (200)', async () => {
  const res = await fetch(`${baseUrl}/api/v1/reviews/user/${driverUser._id}`);

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data.reviews.length, 1);
  assert.strictEqual(body.data.stats.average, 5.0);
});

test('9. In-app notifications: driver can fetch notifications created by messages & reviews', async () => {
  const res = await fetch(`${baseUrl}/api/v1/notifications`, {
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert(body.data.notifications.length >= 1);
  assert(body.data.unreadCount >= 1);

  const notifId = body.data.notifications[0]._id;

  // Mark single as read
  const markRes = await fetch(`${baseUrl}/api/v1/notifications/${notifId}/read`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });
  assert.strictEqual(markRes.status, 200);

  // Mark all as read
  const markAllRes = await fetch(`${baseUrl}/api/v1/notifications/read-all`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${driverToken}`,
    },
  });
  assert.strictEqual(markAllRes.status, 200);
  const markAllBody = await markAllRes.json();
  assert.strictEqual(markAllBody.unreadCount, 0);
});
