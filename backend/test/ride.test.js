const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let userA;
let tokenA;
let vehicleA;

let userB;
let tokenB;
let vehicleB;

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

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  // Create User A (Driver)
  userA = await User.create({
    name: 'Karan Dave',
    email: 'karan.driver@example.com',
    phone: '+919876500011',
    password: 'Password123@#',
    city: 'Bhuj',
    isVerified: true,
  });
  tokenA = jwt.sign({ id: userA._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // Create Vehicle for User A (Capacity: 4)
  vehicleA = await Vehicle.create({
    owner: userA._id,
    registrationNumber: 'GJ12CD5678',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'White',
    seatCapacity: 4,
    status: 'active',
  });

  // Create User B (Another User)
  userB = await User.create({
    name: 'Priya Joshi',
    email: 'priya.user@example.com',
    phone: '+919876500012',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  tokenB = jwt.sign({ id: userB._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // Create Vehicle for User B (Capacity: 2)
  vehicleB = await Vehicle.create({
    owner: userB._id,
    registrationNumber: 'GJ01EF9999',
    vehicleType: 'hatchback',
    make: 'Hyundai',
    model: 'i20',
    year: 2021,
    color: 'Silver',
    seatCapacity: 2,
    status: 'active',
  });
});

test.after(async () => {
  await Ride.deleteMany({});
  await Vehicle.deleteMany({});
  await User.deleteMany({});
  await mongoose.connection.close();
  if (mongoServer) {
    await mongoServer.stop();
  }
  server.close();
});

test('RIDES: Unauthenticated requests to /api/v1/rides and /rides/my are rejected with 401', async () => {
  const getMyRes = await fetch(`${baseUrl}/rides/my`);
  assert.strictEqual(getMyRes.status, 401);

  const postRes = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ vehicleId: vehicleA._id.toString() }),
  });
  assert.strictEqual(postRes.status, 401);
});

test('RIDES: Create ride with missing required fields is rejected with 400', async () => {
  // Missing origin & destination
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleA._id.toString(),
    }),
  });
  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('RIDES: Create ride with invalid coordinates is rejected with 400', async () => {
  const futureDeparture = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleA._id.toString(),
      origin: { name: 'Bhuj', latitude: 999.0, longitude: 69.6669 },
      destination: { name: 'Ahmedabad', latitude: 23.0225, longitude: 72.5714 },
      route: {
        encodedPolyline: 'a~l~Fjk~uOnw@...',
        distanceMeters: 330000,
        durationSeconds: 21600,
      },
      departureTime: futureDeparture,
      availableSeats: 3,
      contributionPerSeat: 450,
    }),
  });
  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('RIDES: Create ride with identical origin and destination is rejected with 400', async () => {
  const futureDeparture = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleA._id.toString(),
      origin: { name: 'Bhuj Station', latitude: 23.242, longitude: 69.6669 },
      destination: { name: 'Bhuj Station', latitude: 23.242, longitude: 69.6669 },
      route: {
        encodedPolyline: 'a~l~F...',
        distanceMeters: 1000,
        durationSeconds: 300,
      },
      departureTime: futureDeparture,
      availableSeats: 3,
      contributionPerSeat: 50,
    }),
  });
  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /identical/i);
});

test('RIDES: Create ride with vehicle owned by another user is rejected with 403 Forbidden', async () => {
  const futureDeparture = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  // User A tries to use User B's vehicle
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleB._id.toString(),
      origin: { name: 'Bhuj', latitude: 23.242, longitude: 69.6669 },
      destination: { name: 'Ahmedabad', latitude: 23.0225, longitude: 72.5714 },
      route: {
        encodedPolyline: 'polyline_abc_123',
        distanceMeters: 330000,
        durationSeconds: 21600,
      },
      departureTime: futureDeparture,
      availableSeats: 2,
      contributionPerSeat: 400,
    }),
  });
  assert.strictEqual(res.status, 403);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /do not own/i);
});

test('RIDES: Create ride with available seats exceeding vehicle capacity is rejected with 400', async () => {
  const futureDeparture = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  // vehicleA capacity is 4. User A tries to offer 5 seats.
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleA._id.toString(),
      origin: { name: 'Bhuj', latitude: 23.242, longitude: 69.6669 },
      destination: { name: 'Ahmedabad', latitude: 23.0225, longitude: 72.5714 },
      route: {
        encodedPolyline: 'polyline_abc_123',
        distanceMeters: 330000,
        durationSeconds: 21600,
      },
      departureTime: futureDeparture,
      availableSeats: 5,
      contributionPerSeat: 400,
    }),
  });
  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /cannot exceed vehicle capacity/i);
});

test('RIDES: Create ride with negative contribution is rejected with 400', async () => {
  const futureDeparture = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleA._id.toString(),
      origin: { name: 'Bhuj', latitude: 23.242, longitude: 69.6669 },
      destination: { name: 'Ahmedabad', latitude: 23.0225, longitude: 72.5714 },
      route: {
        encodedPolyline: 'polyline_abc_123',
        distanceMeters: 330000,
        durationSeconds: 21600,
      },
      departureTime: futureDeparture,
      availableSeats: 3,
      contributionPerSeat: -50,
    }),
  });
  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

let createdRideId;

test('RIDES: Valid ride creation succeeds with 201 and persists GeoJSON 2dsphere points', async () => {
  const departureDate = new Date(Date.now() + 36 * 60 * 60 * 1000);
  const res = await fetch(`${baseUrl}/rides`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      vehicleId: vehicleA._id.toString(),
      origin: {
        name: 'Jubilee Ground, Bhuj',
        latitude: 23.242,
        longitude: 69.6669,
        placeId: 'ChIJb_places_bhuj_01',
      },
      destination: {
        name: 'ISCON Cross Road, Ahmedabad',
        latitude: 23.0225,
        longitude: 72.5714,
        placeId: 'ChIJb_places_ahmedabad_01',
      },
      route: {
        encodedPolyline: 'w~dfD_bswM_route_encoded_bhuj_amd',
        distanceMeters: 332000,
        durationSeconds: 21600,
      },
      departureTime: departureDate.toISOString(),
      availableSeats: 3,
      contributionPerSeat: 450,
      pickupPolicy: 'nearby',
      amenities: ['AC', 'Luggage Space', 'Music'],
      notes: 'Departing promptly on time. Luggage allowed in boot.',
    }),
  });

  assert.strictEqual(res.status, 201);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.ok(data.ride.id);
  createdRideId = data.ride.id;

  assert.strictEqual(data.ride.origin.name, 'Jubilee Ground, Bhuj');
  assert.strictEqual(data.ride.origin.point.type, 'Point');
  assert.deepStrictEqual(data.ride.origin.point.coordinates, [69.6669, 23.242]);

  assert.strictEqual(data.ride.destination.name, 'ISCON Cross Road, Ahmedabad');
  assert.strictEqual(data.ride.destination.point.type, 'Point');
  assert.deepStrictEqual(data.ride.destination.point.coordinates, [72.5714, 23.0225]);

  assert.strictEqual(data.ride.availableSeats, 3);
  assert.strictEqual(data.ride.totalSeats, 4);
  assert.strictEqual(data.ride.contributionPerSeat, 450);
  assert.strictEqual(data.ride.status, 'scheduled');
  assert.strictEqual(data.ride.pickupPolicy, 'nearby');
  assert.strictEqual(data.ride.vehicle.make, 'Honda');
  assert.strictEqual(data.ride.driver.name, 'Karan Dave');
});

test('RIDES: Driver can retrieve their own rides via GET /api/v1/rides/my', async () => {
  const res = await fetch(`${baseUrl}/rides/my`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.count, 1);
  assert.strictEqual(data.rides[0].id, createdRideId);
});

test('RIDES: Get ride by ID returns 200 and populated details', async () => {
  const res = await fetch(`${baseUrl}/rides/${createdRideId}`);
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.id, createdRideId);
  assert.strictEqual(data.ride.driver.name, 'Karan Dave');
  assert.strictEqual(data.ride.vehicle.model, 'City');
});

test('RIDES: Another user cannot update driver ride (403 Forbidden)', async () => {
  const res = await fetch(`${baseUrl}/rides/${createdRideId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`, // User B tries to update User A's ride
    },
    body: JSON.stringify({
      contributionPerSeat: 100,
    }),
  });
  assert.strictEqual(res.status, 403);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('RIDES: Driver can update their own scheduled ride with 200', async () => {
  const res = await fetch(`${baseUrl}/rides/${createdRideId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      contributionPerSeat: 400,
      availableSeats: 2,
      notes: 'Updated departure notes.',
    }),
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.contributionPerSeat, 400);
  assert.strictEqual(data.ride.availableSeats, 2);
  assert.strictEqual(data.ride.notes, 'Updated departure notes.');
});

test('RIDES: Driver can cancel their own ride with 200', async () => {
  const res = await fetch(`${baseUrl}/rides/${createdRideId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  if (res.status !== 200) {
    console.error('Cancel Ride Error:', res.status, await res.text());
  }
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.status, 'cancelled');

  // Attempting to cancel again should fail
  const repeatRes = await fetch(`${baseUrl}/rides/${createdRideId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(repeatRes.status, 400);
});
