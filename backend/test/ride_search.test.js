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

let driverA;
let tokenDriverA;
let vehicleA;

let driverB;
let tokenDriverB;
let vehicleB;

let passengerUser;
let tokenPassenger;

let rideBhujToAhmedabad;
let rideAhmedabadToRajkot;
let rideCancelled;
let rideOneSeat;

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

  // Create Driver A (Bhuj based)
  driverA = await User.create({
    name: 'Harsh Vardhan',
    email: 'harsh.driver@example.com',
    phone: '+919876500021',
    password: 'Password123@#',
    city: 'Bhuj',
    isVerified: true,
  });
  tokenDriverA = jwt.sign({ id: driverA._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  vehicleA = await Vehicle.create({
    owner: driverA._id,
    registrationNumber: 'GJ12AA1111',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'White',
    seatCapacity: 4,
    status: 'active',
  });

  // Create Driver B (Ahmedabad based)
  driverB = await User.create({
    name: 'Suresh Patel',
    email: 'suresh.driver@example.com',
    phone: '+919876500022',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  tokenDriverB = jwt.sign({ id: driverB._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  vehicleB = await Vehicle.create({
    owner: driverB._id,
    registrationNumber: 'GJ01BB2222',
    vehicleType: 'suv',
    make: 'Hyundai',
    model: 'Creta',
    year: 2023,
    color: 'Silver',
    seatCapacity: 4,
    status: 'active',
  });

  // Create Passenger User
  passengerUser = await User.create({
    name: 'Ananya Roy',
    email: 'ananya.passenger@example.com',
    phone: '+919876500023',
    password: 'Password123@#',
    city: 'Anjar',
    isVerified: true,
  });
  tokenPassenger = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // Ensure 2dsphere indexes are built
  await Ride.syncIndexes();

  const baseDeparture = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h from now

  // 1. Ride from Bhuj to Ahmedabad (passes near Anjar)
  rideBhujToAhmedabad = await Ride.create({
    driver: driverA._id,
    vehicle: vehicleA._id,
    origin: {
      name: 'Bhuj Bus Station',
      latitude: 23.2420,
      longitude: 69.6669,
      point: { type: 'Point', coordinates: [69.6669, 23.2420] },
    },
    destination: {
      name: 'Ahmedabad Geeta Mandir',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    route: {
      encodedPolyline: 'mock_bhuj_ahmedabad_polyline',
      distanceMeters: 380000,
      durationSeconds: 25200,
    },
    departureTime: baseDeparture,
    estimatedArrivalTime: new Date(baseDeparture.getTime() + 7 * 3600 * 1000),
    availableSeats: 3,
    totalSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 450,
    pickupPolicy: 'nearby',
    amenities: ['AC', 'Music'],
    status: 'scheduled',
  });

  // 2. Ride from Ahmedabad to Rajkot
  rideAhmedabadToRajkot = await Ride.create({
    driver: driverB._id,
    vehicle: vehicleB._id,
    origin: {
      name: 'Ahmedabad Iscon Cross Road',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    destination: {
      name: 'Rajkot Trikon Baug',
      latitude: 22.3039,
      longitude: 70.8022,
      point: { type: 'Point', coordinates: [70.8022, 22.3039] },
    },
    route: {
      encodedPolyline: 'mock_ahmedabad_rajkot_polyline',
      distanceMeters: 215000,
      durationSeconds: 14400,
    },
    departureTime: new Date(baseDeparture.getTime() + 4 * 3600 * 1000),
    estimatedArrivalTime: new Date(baseDeparture.getTime() + 8 * 3600 * 1000),
    availableSeats: 2,
    totalSeats: 4,
    bookedSeats: 1,
    contributionPerSeat: 320,
    pickupPolicy: 'exact',
    amenities: ['AC'],
    status: 'scheduled',
  });

  // 3. Cancelled Ride (should be excluded)
  rideCancelled = await Ride.create({
    driver: driverA._id,
    vehicle: vehicleA._id,
    origin: {
      name: 'Bhuj Jubilee Ground',
      latitude: 23.2420,
      longitude: 69.6669,
      point: { type: 'Point', coordinates: [69.6669, 23.2420] },
    },
    destination: {
      name: 'Ahmedabad Paldi',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    route: {
      encodedPolyline: 'mock_cancelled_polyline',
      distanceMeters: 380000,
      durationSeconds: 25200,
    },
    departureTime: baseDeparture,
    estimatedArrivalTime: new Date(baseDeparture.getTime() + 7 * 3600 * 1000),
    availableSeats: 3,
    totalSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 400,
    status: 'cancelled',
  });

  // 4. Ride with only 1 seat available
  rideOneSeat = await Ride.create({
    driver: driverB._id,
    vehicle: vehicleB._id,
    origin: {
      name: 'Bhuj Station',
      latitude: 23.2420,
      longitude: 69.6669,
      point: { type: 'Point', coordinates: [69.6669, 23.2420] },
    },
    destination: {
      name: 'Ahmedabad SG Highway',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    route: {
      encodedPolyline: 'mock_one_seat_polyline',
      distanceMeters: 380000,
      durationSeconds: 25200,
    },
    departureTime: baseDeparture,
    estimatedArrivalTime: new Date(baseDeparture.getTime() + 7 * 3600 * 1000),
    availableSeats: 1,
    totalSeats: 4,
    bookedSeats: 3,
    contributionPerSeat: 500,
    status: 'scheduled',
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

test('GET /api/v1/rides/search - passenger finds available ride with matching origin and destination coordinates', async () => {
  // Passenger is in Bhuj (23.2420, 69.6669) going to Ahmedabad (23.0225, 72.5714)
  const res = await fetch(
    `${baseUrl}/rides/search?originLat=23.2420&originLng=69.6669&destLat=23.0225&destLng=72.5714&seats=1`
  );
  assert.strictEqual(res.status, 200);

  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.ok(data.results.length >= 1);

  // Check structured result fields
  const first = data.results[0];
  assert.ok(first.ride);
  assert.ok(typeof first.pickupDistanceKm === 'number');
  assert.ok(typeof first.destinationDistanceKm === 'number');
  assert.ok(typeof first.departureDifferenceMinutes === 'number');
  assert.ok(typeof first.matchPreview === 'string');
  assert.strictEqual(first.ride.status, 'scheduled');
  assert.ok(first.ride.driver.name);
  assert.ok(first.ride.vehicle.make);
});

test('GET /api/v1/rides/search - excludes cancelled rides from search results', async () => {
  const res = await fetch(
    `${baseUrl}/rides/search?originLat=23.2420&originLng=69.6669&destLat=23.0225&destLng=72.5714`
  );
  const data = await res.json();
  assert.strictEqual(data.success, true);

  const statuses = data.results.map((r) => r.ride.status);
  assert.ok(!statuses.includes('cancelled'));
  assert.ok(!statuses.includes('completed'));
});

test('GET /api/v1/rides/search - excludes rides with fewer available seats than requested', async () => {
  // Requesting 2 seats should exclude rideOneSeat (which only has 1 available seat)
  const res = await fetch(
    `${baseUrl}/rides/search?originLat=23.2420&originLng=69.6669&destLat=23.0225&destLng=72.5714&seats=2`
  );
  const data = await res.json();
  assert.strictEqual(data.success, true);

  for (const item of data.results) {
    assert.ok(item.ride.availableSeats >= 2);
    assert.notStrictEqual(item.ride._id || item.ride.id, rideOneSeat._id.toString());
  }
});

test('GET /api/v1/rides/search - excludes driver own rides when searching as authenticated driver', async () => {
  // Driver A offers the Bhuj to Ahmedabad ride. When Driver A searches, their own ride must be excluded.
  const res = await fetch(
    `${baseUrl}/rides/search?originLat=23.2420&originLng=69.6669&destLat=23.0225&destLng=72.5714`,
    {
      headers: {
        Authorization: `Bearer ${tokenDriverA}`,
      },
    }
  );
  const data = await res.json();
  assert.strictEqual(data.success, true);

  for (const item of data.results) {
    const driverId = item.ride.driver._id || item.ride.driver.id || item.ride.driver;
    assert.notStrictEqual(driverId.toString(), driverA._id.toString());
  }
});

test('GET /api/v1/rides/search - guest search works seamlessly without auth token', async () => {
  const res = await fetch(
    `${baseUrl}/rides/search?originLat=23.0225&originLng=72.5714&destLat=22.3039&destLng=70.8022`
  );
  assert.strictEqual(res.status, 200);

  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.ok(data.results.length >= 1);
  assert.strictEqual(data.results[0].ride.origin.name, 'Ahmedabad Iscon Cross Road');
});

test('GET /api/v1/rides/search - city text query resolves via known hub coordinates', async () => {
  const res = await fetch(
    `${baseUrl}/rides/search?originText=Bhuj&destText=Ahmedabad&seats=1`
  );
  assert.strictEqual(res.status, 200);

  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.ok(data.results.length >= 1);
});

test('GET /api/v1/rides/search - validates invalid coordinates and passenger count', async () => {
  // Invalid latitude
  const res1 = await fetch(
    `${baseUrl}/rides/search?originLat=150&originLng=72.5714`
  );
  assert.strictEqual(res1.status, 400);
  const data1 = await res1.json();
  assert.strictEqual(data1.success, false);

  // Invalid seats count (0)
  const res2 = await fetch(
    `${baseUrl}/rides/search?originLat=23.0225&originLng=72.5714&seats=0`
  );
  assert.strictEqual(res2.status, 400);
  const data2 = await res2.json();
  assert.strictEqual(data2.success, false);

  // Invalid seats count (> 8)
  const res3 = await fetch(
    `${baseUrl}/rides/search?originLat=23.0225&originLng=72.5714&seats=10`
  );
  assert.strictEqual(res3.status, 400);
  const data3 = await res3.json();
  assert.strictEqual(data3.success, false);
});
