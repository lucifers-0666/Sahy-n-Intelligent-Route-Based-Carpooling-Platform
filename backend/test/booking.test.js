const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');
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

let thirdPartyUser;
let thirdPartyToken;

let activeRide;

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
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  // 1. Driver User
  driverUser = await User.create({
    name: 'Rajesh Driver',
    email: 'rajesh.driver@example.com',
    phone: '+919876540001',
    password: 'Password123@#',
    city: 'Bhuj',
    isVerified: true,
  });
  driverToken = jwt.sign({ id: driverUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  driverVehicle = await Vehicle.create({
    owner: driverUser._id,
    registrationNumber: 'GJ12BK1234',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'Silver',
    seatCapacity: 4,
    status: 'active',
  });

  // 2. Passenger User
  passengerUser = await User.create({
    name: 'Pooja Passenger',
    email: 'pooja.passenger@example.com',
    phone: '+919876540002',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // 3. Third party User (unauthorized)
  thirdPartyUser = await User.create({
    name: 'Suresh Stranger',
    email: 'suresh.stranger@example.com',
    phone: '+919876540003',
    password: 'Password123@#',
    city: 'Rajkot',
    isVerified: true,
  });
  thirdPartyToken = jwt.sign({ id: thirdPartyUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });
});

test.beforeEach(async () => {
  await Booking.deleteMany({});
  await Ride.deleteMany({});

  // Fresh scheduled ride: departure 2 days in future, 3 available seats out of 3 total seats, 350 contribution
  const departureDate = new Date();
  departureDate.setDate(departureDate.getDate() + 2);
  const arrivalDate = new Date(departureDate.getTime() + 5 * 3600 * 1000);

  activeRide = await Ride.create({
    driver: driverUser._id,
    vehicle: driverVehicle._id,
    origin: {
      name: 'Bhuj Jubilee Ground',
      latitude: 23.2420,
      longitude: 69.6669,
      point: { type: 'Point', coordinates: [69.6669, 23.2420] },
    },
    destination: {
      name: 'Ahmedabad ISKCON Cross Road',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    route: {
      encodedPolyline: 'u{~nE_w~vOu`@z_@',
      distanceMeters: 330000,
      durationSeconds: 19800,
    },
    departureTime: departureDate,
    estimatedArrivalTime: arrivalDate,
    availableSeats: 3,
    totalSeats: 3,
    bookedSeats: 0,
    contributionPerSeat: 350,
    pickupPolicy: 'nearby',
    status: 'scheduled',
  });
});

test.after(async () => {
  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});
  if (server) server.close();
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  if (mongoServer) {
    await mongoServer.stop();
  }
});

test('BOOKINGS: Unauthenticated request to /bookings is rejected with 401', async () => {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res.status, 401);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('BOOKINGS: Driver cannot book their own ride (400 Bad Request)', async () => {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /Drivers cannot book/i);
});

test('BOOKINGS: Non-existent ride is rejected with 404', async () => {
  const fakeId = new mongoose.Types.ObjectId().toString();
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: fakeId,
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res.status, 404);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('BOOKINGS: Cancelled ride rejects booking requests with 409 Conflict', async () => {
  await Ride.findByIdAndUpdate(activeRide._id, { status: 'cancelled' });

  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('BOOKINGS: Completed ride rejects booking requests with 409 Conflict', async () => {
  await Ride.findByIdAndUpdate(activeRide._id, { status: 'completed' });

  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('BOOKINGS: Already departed ride rejects booking requests with 409 Conflict', async () => {
  const pastDate = new Date();
  pastDate.setHours(pastDate.getHours() - 2);
  await Ride.findByIdAndUpdate(activeRide._id, { departureTime: pastDate });

  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /departed/i);
});

test('BOOKINGS: Invalid seat count (< 1 or non-integer) is rejected with 400', async () => {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 0,
    }),
  });

  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('BOOKINGS: Authenticated passenger creates booking (201) with server-side total and capacity reservation', async () => {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 2,
      passengerNote: 'Please wait near Jubilee bus stop',
    }),
  });

  assert.strictEqual(res.status, 201);
  const json = await res.json();
  assert.strictEqual(json.success, true);
  assert.strictEqual(json.data.status, 'pending');
  assert.strictEqual(json.data.requestedSeats, 2);
  assert.strictEqual(json.data.contributionPerSeat, 350);
  assert.strictEqual(json.data.totalContribution, 700);
  assert.strictEqual(json.data.passengerNote, 'Please wait near Jubilee bus stop');
  assert.ok(json.data.pickup && json.data.pickup.name);
  assert.ok(json.data.drop && json.data.drop.name);

  // Verify atomic seat reservation on the Ride model: availableSeats should be 3 - 2 = 1
  const updatedRide = await Ride.findById(activeRide._id);
  assert.strictEqual(updatedRide.availableSeats, 1);
});

test('BOOKINGS: Insufficient capacity rejects request with 409 Conflict', async () => {
  // activeRide has 3 available seats. Requesting 4 seats must be rejected.
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 4,
    }),
  });

  assert.strictEqual(res.status, 409);
  const json = await res.json();
  assert.strictEqual(json.success, false);

  // Available seats should remain unchanged
  const ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 3);
});

test('BOOKINGS: Duplicate pending booking for same ride is rejected with 409 Conflict', async () => {
  // First booking for 1 seat succeeds
  const res1 = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });
  assert.strictEqual(res1.status, 201);

  // Second booking by same passenger for same ride must be rejected
  const res2 = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  assert.strictEqual(res2.status, 409);
  const json = await res2.json();
  assert.strictEqual(json.success, false);
  assert.match(json.message, /active booking request/i);
});

test('BOOKINGS: GET /bookings/my returns only authenticated passenger bookings with pagination', async () => {
  // Create booking for passenger
  await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });

  // Fetch as passenger
  const resPassenger = await fetch(`${baseUrl}/bookings/my?page=1&limit=10`, {
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(resPassenger.status, 200);
  const jsonPassenger = await resPassenger.json();
  assert.strictEqual(jsonPassenger.success, true);
  assert.strictEqual(jsonPassenger.total, 1);
  assert.strictEqual(jsonPassenger.data.length, 1);
  assert.strictEqual(jsonPassenger.data[0].requestedSeats, 1);

  // Fetch as third party (should have 0 bookings)
  const resStranger = await fetch(`${baseUrl}/bookings/my`, {
    headers: { Authorization: `Bearer ${thirdPartyToken}` },
  });
  assert.strictEqual(resStranger.status, 200);
  const jsonStranger = await resStranger.json();
  assert.strictEqual(jsonStranger.total, 0);
  assert.strictEqual(jsonStranger.data.length, 0);
});

test('BOOKINGS: GET /bookings/:id allows passenger and driver, rejects unauthorized third party with 403', async () => {
  // Create booking
  const createRes = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
    }),
  });
  const createJson = await createRes.json();
  const bookingId = createJson.data.id;

  // Passenger can view
  const resPassenger = await fetch(`${baseUrl}/bookings/${bookingId}`, {
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(resPassenger.status, 200);

  // Driver of the ride can view
  const resDriver = await fetch(`${baseUrl}/bookings/${bookingId}`, {
    headers: { Authorization: `Bearer ${driverToken}` },
  });
  assert.strictEqual(resDriver.status, 200);

  // Third party cannot view (403 Forbidden)
  const resStranger = await fetch(`${baseUrl}/bookings/${bookingId}`, {
    headers: { Authorization: `Bearer ${thirdPartyToken}` },
  });
  assert.strictEqual(resStranger.status, 403);
});

test('BOOKINGS: Passenger cancels pending booking, releases capacity back to ride', async () => {
  // 1. Book 2 seats on ride (initially 3 available)
  const createRes = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 2,
    }),
  });
  const createJson = await createRes.json();
  const bookingId = createJson.data.id;

  let ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 1);

  // 2. Third party cannot cancel passenger booking (403)
  const strangerCancel = await fetch(`${baseUrl}/bookings/${bookingId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${thirdPartyToken}` },
  });
  assert.strictEqual(strangerCancel.status, 403);

  // 3. Passenger cancels own booking
  const cancelRes = await fetch(`${baseUrl}/bookings/${bookingId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(cancelRes.status, 200);
  const cancelJson = await cancelRes.json();
  assert.strictEqual(cancelJson.data.status, 'cancelled');

  // 4. Capacity must be restored back to ride (1 + 2 = 3)
  ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 3);

  // 5. Repeated cancel request is rejected
  const repeatCancel = await fetch(`${baseUrl}/bookings/${bookingId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(repeatCancel.status, 400);
});

test('BOOKINGS: Concurrent capacity safety prevents overbooking', async () => {
  // activeRide has 3 seats. User A (passenger) requests 2 seats, User B (thirdParty) requests 2 seats concurrently.
  // Exactly one must succeed with 201, and the other must fail with 409 (insufficient seats).
  const [resA, resB] = await Promise.all([
    fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        rideId: activeRide._id.toString(),
        requestedSeats: 2,
      }),
    }),
    fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${thirdPartyToken}`,
      },
      body: JSON.stringify({
        rideId: activeRide._id.toString(),
        requestedSeats: 2,
      }),
    }),
  ]);

  const statuses = [resA.status, resB.status].sort();
  assert.deepStrictEqual(statuses, [201, 409]);

  const ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 1);
});
