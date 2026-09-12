const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');

let mongoServer;
let server;
let baseUrl;

// Shared test entities
let driverUser;
let driverToken;
let driverVehicle;
let driverRide;

let passengerUser;
let passengerToken;

let unauthorizedUser;
let unauthorizedToken;

let activeBookingId;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());
  } catch (_) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_phase1_test';
    await mongoose.connect(mongoUri);
  }

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});
  await Booking.deleteMany({});

  server = app.listen(0);
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}/api`;
});

test.after(async () => {
  await Booking.deleteMany({});
  await Ride.deleteMany({});
  await Vehicle.deleteMany({});
  await User.deleteMany({});
  await mongoose.connection.close();
  if (mongoServer) {
    await mongoServer.stop();
  }
  if (server) {
    server.close();
  }
});

// 1. Health endpoint responds successfully
test('1. Health endpoint responds successfully (GET /api/health)', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.strictEqual(res.status, 200);

  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.message, 'RouteShare API is running');
  assert.ok(body.data);
  assert.ok(body.data.environment);
});

// 2. User registration succeeds with valid details
test('2. User registration succeeds with valid details (POST /api/auth/register)', async () => {
  const payload = {
    name: 'Vikram Mehta',
    email: 'vikram.driver@example.com',
    phone: '9876543211',
    password: 'Password123@#',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.ok(body.data || body.user);
  const user = body.data?.user || body.user;
  assert.strictEqual(user.email, 'vikram.driver@example.com');
  assert.strictEqual(user.phone, '+919876543211');
  assert.strictEqual(user.password, undefined); // Password hash must never be returned
});

// 3. Registration rejects duplicate user
test('3. Registration rejects a duplicate user with duplicate email or phone (400)', async () => {
  const duplicateEmailPayload = {
    name: 'Duplicate Vikram',
    email: 'vikram.driver@example.com',
    phone: '9876543212',
    password: 'Password123@#',
  };

  const res1 = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(duplicateEmailPayload),
  });
  assert.strictEqual(res1.status, 400);
  const body1 = await res1.json();
  assert.strictEqual(body1.success, false);

  const duplicatePhonePayload = {
    name: 'Another Vikram',
    email: 'another.vikram@example.com',
    phone: '9876543211',
    password: 'Password123@#',
  };

  const res2 = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(duplicatePhonePayload),
  });
  assert.strictEqual(res2.status, 400);
  const body2 = await res2.json();
  assert.strictEqual(body2.success, false);
});

// 4. Login returns a JWT for valid credentials
test('4. Login returns a JWT for valid credentials (POST /api/auth/login)', async () => {
  // Mark driver verified to allow login
  driverUser = await User.findOne({ email: 'vikram.driver@example.com' });
  driverUser.isVerified = true;
  await driverUser.save();

  const loginPayload = {
    identifier: 'vikram.driver@example.com',
    password: 'Password123@#',
  };

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(loginPayload),
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  driverToken = body.token || body.data?.token || body.accessToken;
  assert.ok(driverToken);
  assert.strictEqual(body.user?.password, undefined);

  // Also create passenger and unauthorized user for upcoming tests
  passengerUser = await User.create({
    name: 'Priya Sharma',
    email: 'priya.passenger@example.com',
    phone: '+919876543213',
    password: 'Password123@#',
    isVerified: true,
  });

  const passengerLoginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: 'priya.passenger@example.com', password: 'Password123@#' }),
  });
  const passengerLoginBody = await passengerLoginRes.json();
  passengerToken = passengerLoginBody.token || passengerLoginBody.data?.token;

  unauthorizedUser = await User.create({
    name: 'Rohan Verma',
    email: 'rohan.other@example.com',
    phone: '+919876543214',
    password: 'Password123@#',
    isVerified: true,
  });

  const unauthorizedLoginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: 'rohan.other@example.com', password: 'Password123@#' }),
  });
  const unauthorizedLoginBody = await unauthorizedLoginRes.json();
  unauthorizedToken = unauthorizedLoginBody.token || unauthorizedLoginBody.data?.token;
});

// 5. Protected route rejects requests without JWT
test('5. Protected route rejects requests without JWT (GET /api/auth/me)', async () => {
  // Without token -> 401
  const unauthRes = await fetch(`${baseUrl}/auth/me`);
  assert.strictEqual(unauthRes.status, 401);

  // With invalid token -> 401
  const invalidRes = await fetch(`${baseUrl}/auth/me`, {
    headers: { Authorization: 'Bearer invalid_token_12345' },
  });
  assert.strictEqual(invalidRes.status, 401);

  // With valid token -> 200
  const authRes = await fetch(`${baseUrl}/auth/me`, {
    headers: { Authorization: `Bearer ${driverToken}` },
  });
  assert.strictEqual(authRes.status, 200);
  const authBody = await authRes.json();
  assert.strictEqual(authBody.success, true);
  const me = authBody.data?.user || authBody.user;
  assert.strictEqual(me.email, 'vikram.driver@example.com');
  assert.strictEqual(me.password, undefined);
});

// 6. Vehicle creation works for an authenticated user
test('6. Vehicle creation works for an authenticated user (POST /api/vehicles)', async () => {
  const vehiclePayload = {
    registrationNumber: 'GJ01AB1234',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'Silver',
    seatCapacity: 4,
  };

  const res = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify(vehiclePayload),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  driverVehicle = body.data?.vehicle || body.vehicle;
  assert.strictEqual(driverVehicle.registrationNumber, 'GJ01AB1234');
  assert.strictEqual(driverVehicle.seatCapacity, 4);

  // Verify driver capability enabled
  const updatedUser = await User.findById(driverUser._id);
  assert.strictEqual(updatedUser.capabilities.canDrive, true);
});

// 7. A user cannot update/delete another user’s vehicle
test('7. A user cannot update/delete another user’s vehicle (403 Forbidden)', async () => {
  // Passenger attempts to update driver's vehicle
  const updateRes = await fetch(`${baseUrl}/vehicles/${driverVehicle._id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({ color: 'Neon Green' }),
  });
  assert.strictEqual(updateRes.status, 403);

  // Passenger attempts to delete driver's vehicle
  const deleteRes = await fetch(`${baseUrl}/vehicles/${driverVehicle._id}`, {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${passengerToken}`,
    },
  });
  assert.strictEqual(deleteRes.status, 403);
});

// 8. Driver creates a ride using their own vehicle
test('8. Driver creates a ride using their own vehicle (POST /api/rides)', async () => {
  const departureDate = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h in future
  const arrivalDate = new Date(departureDate.getTime() + 4 * 60 * 60 * 1000);

  const ridePayload = {
    vehicleId: driverVehicle._id,
    origin: {
      name: 'Ahmedabad ISKCON Cross Road',
      latitude: 23.0225,
      longitude: 72.5714,
    },
    destination: {
      name: 'Vadodara Central Bus Station',
      latitude: 22.3072,
      longitude: 73.1812,
    },
    route: {
      encodedPolyline: 'mock_polyline_ahmedabad_vadodara',
      distanceMeters: 110000,
      durationSeconds: 7200,
    },
    departureTime: departureDate.toISOString(),
    estimatedArrivalTime: arrivalDate.toISOString(),
    availableSeats: 4,
    contributionPerSeat: 250,
    pickupPolicy: 'nearby',
    amenities: ['AC', 'Music'],
    notes: 'Leaving on time, comfortable drive.',
  };

  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify(ridePayload),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  driverRide = body.data?.ride || body.ride;
  assert.strictEqual(driverRide.availableSeats, 4);
  assert.strictEqual(driverRide.status, 'scheduled');
});

// 9. Passenger can search available upcoming rides
test('9. Passenger can search available upcoming rides (GET /api/rides/search)', async () => {
  const searchUrl = `${baseUrl}/rides/search?originLat=23.0225&originLng=72.5714&destLat=22.3072&destLng=73.1812&seats=1`;
  const res = await fetch(searchUrl, {
    headers: {
      Authorization: `Bearer ${passengerToken}`,
    },
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  const results = body.data?.results || body.results;
  assert.ok(Array.isArray(results));
  assert.ok(results.length >= 1);
  assert.strictEqual(body.data?.page, 1);
  assert.strictEqual(body.data?.limit > 0, true);
});

// 10. Passenger cannot book their own ride
test('10. Passenger cannot book their own ride (400 Bad Request)', async () => {
  const bookOwnRidePayload = {
    rideId: driverRide._id,
    requestedSeats: 1,
    passengerNote: 'Trying to book my own ride',
  };

  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify(bookOwnRidePayload),
  });

  assert.strictEqual(res.status, 400);
  const body = await res.json();
  assert.strictEqual(body.success, false);
  assert.match(body.message, /cannot book.*own ride/i);
});

// 11. Passenger can create a pending booking request
test('11. Passenger can create a pending booking request (POST /api/bookings)', async () => {
  const bookingPayload = {
    rideId: driverRide._id,
    requestedSeats: 2,
    passengerNote: 'Travelling with one bag',
  };

  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify(bookingPayload),
  });

  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  activeBookingId = body.data?.id || body.data?._id;
  assert.ok(activeBookingId);
  assert.strictEqual(body.data?.status, 'pending');
  assert.strictEqual(body.data?.requestedSeats, 2);

  // Verify seat capacity reservation on ride: 4 - 2 = 2
  const ride = await Ride.findById(driverRide._id);
  assert.strictEqual(ride.availableSeats, 2);
});

// 12. Unauthorized user cannot approve a booking
test('12. Unauthorized user cannot approve a booking (403 Forbidden)', async () => {
  const res = await fetch(`${baseUrl}/bookings/${activeBookingId}/status`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${unauthorizedToken}`,
    },
    body: JSON.stringify({ status: 'confirmed' }),
  });

  assert.strictEqual(res.status, 403);
  const body = await res.json();
  assert.strictEqual(body.success, false);
});

// 13. Ride owner can approve a pending booking
test('13. Ride owner can approve a pending booking (PATCH /api/bookings/:id/status)', async () => {
  const res = await fetch(`${baseUrl}/bookings/${activeBookingId}/status`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${driverToken}`,
    },
    body: JSON.stringify({ status: 'confirmed' }),
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data?.status, 'accepted');
});

// 14. Booking approval reduces seat availability correctly
test('14. Booking approval preserves seat availability invariant without double decrement', async () => {
  const ride = await Ride.findById(driverRide._id);
  // Total 4 seats: 2 booked by approved booking, 2 remaining available
  assert.strictEqual(ride.totalSeats, 4);
  assert.strictEqual(ride.bookedSeats, 2);
  assert.strictEqual(ride.availableSeats, 2);
});

// 15. Insufficient-seat booking confirmation is rejected without overbooking
test('15. Insufficient-seat booking request is rejected without overbooking (409 Conflict)', async () => {
  // Attempt to book 3 seats when only 2 are available
  const overbookPayload = {
    rideId: driverRide._id,
    requestedSeats: 3,
    passengerNote: 'Overbooking attempt',
  };

  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${unauthorizedToken}`,
    },
    body: JSON.stringify(overbookPayload),
  });

  assert.strictEqual(res.status, 409);
  const body = await res.json();
  assert.strictEqual(body.success, false);
  assert.match(body.message, /insufficient/i);

  // Available seats must remain untouched
  const ride = await Ride.findById(driverRide._id);
  assert.strictEqual(ride.availableSeats, 2);
});

// 16. Cancelling a confirmed booking restores seats correctly
test('16. Cancelling a confirmed booking restores seats correctly (PATCH /api/bookings/:id/cancel)', async () => {
  const res = await fetch(`${baseUrl}/bookings/${activeBookingId}/cancel`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${passengerToken}`,
    },
  });

  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data?.status, 'cancelled');

  // Verify seat capacity restoration: availableSeats restored from 2 back to 4, bookedSeats decreased from 2 back to 0
  const ride = await Ride.findById(driverRide._id);
  assert.strictEqual(ride.totalSeats, 4);
  assert.strictEqual(ride.availableSeats, 4);
  assert.strictEqual(ride.bookedSeats, 0);
});
