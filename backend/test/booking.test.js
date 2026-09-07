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

  // Ensure indexes are built in MongoMemoryServer
  await Booking.init();
  await Ride.init();
  await User.init();
  await Vehicle.init();

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

// 1. Unauthenticated booking
test('1. Unauthenticated booking request to /bookings is rejected with 401', async () => {
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

// 2. Valid booking
test('2. Valid booking request creates pending reservation (201)', async () => {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 2,
      passengerNote: 'Waiting at the Jubilee bus stop',
    }),
  });

  assert.strictEqual(res.status, 201);
  const json = await res.json();
  assert.strictEqual(json.success, true);
  assert.strictEqual(json.data.status, 'pending');
  assert.strictEqual(json.data.requestedSeats, 2);
  assert.strictEqual(json.data.passengerNote, 'Waiting at the Jubilee bus stop');

  // Verify available seats decreased on Ride
  const ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 1);
});

// 3. Driver cannot book own ride
test('3. Driver cannot book own ride (400 Bad Request)', async () => {
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

// 4. Invalid ride
test('4. Non-existent ride is rejected with 404', async () => {
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

// 5. Cancelled ride
test('5. Cancelled ride rejects booking requests with 409 Conflict', async () => {
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

// 6. Completed ride
test('6. Completed ride rejects booking requests with 409 Conflict', async () => {
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

// 7. Departed ride
test('7. Departed ride rejects booking requests with 409 Conflict', async () => {
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

// 8. Invalid seats
test('8. Invalid seat count (< 1, > 8, non-integer) is rejected with 400', async () => {
  // Test 0 seats
  const resZero = await fetch(`${baseUrl}/bookings`, {
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
  assert.strictEqual(resZero.status, 400);

  // Test > 8 seats
  const resNine = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 9,
    }),
  });
  assert.strictEqual(resNine.status, 400);

  // Test floating point seats
  const resFloat = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1.5,
    }),
  });
  assert.strictEqual(resFloat.status, 400);
});

// 9. Insufficient capacity
test('9. Insufficient capacity rejects request with 409 Conflict', async () => {
  // Ride has 3 seats available; requesting 4 must be rejected
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

  const ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 3);
});

// 10. Duplicate pending booking
test('10. Duplicate pending booking for same ride is rejected with 409 Conflict', async () => {
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

// 11. Duplicate accepted booking
test('11. Duplicate booking rejected if passenger already has an accepted booking (409 Conflict)', async () => {
  // Create an accepted booking directly in DB
  await Booking.create({
    passenger: passengerUser._id,
    ride: activeRide._id,
    requestedSeats: 1,
    contributionPerSeat: 350,
    totalContribution: 350,
    status: 'accepted',
    pickup: activeRide.origin,
    drop: activeRide.destination,
  });

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
  const json = await res.json();
  assert.strictEqual(json.success, false);
  assert.match(json.message, /active booking request/i);
});

// 12. Cancelled previous booking can request again
test('12. Cancelled previous booking allows passenger to request seats again (201)', async () => {
  // Create an initial booking
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
  const booking1 = (await res1.json()).data;

  // Cancel the first booking
  const cancelRes = await fetch(`${baseUrl}/bookings/${booking1.id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(cancelRes.status, 200);

  // Now the passenger should be able to create a new booking on the same ride
  const res2 = await fetch(`${baseUrl}/bookings`, {
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

  assert.strictEqual(res2.status, 201);
  const json2 = await res2.json();
  assert.strictEqual(json2.success, true);
  assert.strictEqual(json2.data.status, 'pending');
  assert.strictEqual(json2.data.requestedSeats, 2);
});

// 13. Server-side contribution calculation
test('13. Server-side contribution calculation is authoritative (seats * contributionPerSeat)', async () => {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 3,
      // Attempting to inject client-side amounts should be completely ignored
      contributionPerSeat: 10,
      totalContribution: 30,
    }),
  });

  assert.strictEqual(res.status, 201);
  const json = await res.json();
  assert.strictEqual(json.data.contributionPerSeat, 350);
  assert.strictEqual(json.data.totalContribution, 1050); // 3 * 350
});

// 14. Pickup/drop validation
test('14. Pickup/drop validation rejects invalid coordinates or empty names with 400', async () => {
  // Out of range latitude (> 90)
  const resBadLat = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
      pickup: {
        name: 'Invalid Point',
        latitude: 95.0,
        longitude: 70.0,
      },
    }),
  });
  assert.strictEqual(resBadLat.status, 400);

  // Out of range longitude (< -180)
  const resBadLng = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
      drop: {
        name: 'Invalid Point',
        latitude: 23.0,
        longitude: -185.0,
      },
    }),
  });
  assert.strictEqual(resBadLng.status, 400);

  // Non-numeric coordinate
  const resNonNumeric = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
      pickup: {
        name: 'Invalid Point',
        latitude: 'twenty-three',
        longitude: 70.0,
      },
    }),
  });
  assert.strictEqual(resNonNumeric.status, 400);

  // Empty name
  const resEmptyName = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerToken}`,
    },
    body: JSON.stringify({
      rideId: activeRide._id.toString(),
      requestedSeats: 1,
      pickup: {
        name: '   ',
        latitude: 23.0,
        longitude: 70.0,
      },
    }),
  });
  assert.strictEqual(resEmptyName.status, 400);
});

// 15. Unauthorized booking details
test('15. Unauthorized third party cannot view booking details (403)', async () => {
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
  const bookingId = (await createRes.json()).data.id;

  const resStranger = await fetch(`${baseUrl}/bookings/${bookingId}`, {
    headers: { Authorization: `Bearer ${thirdPartyToken}` },
  });
  assert.strictEqual(resStranger.status, 403);
});

// 16. Passenger booking details
test('16. Passenger can view own booking details (200)', async () => {
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
  const bookingId = (await createRes.json()).data.id;

  const res = await fetch(`${baseUrl}/bookings/${bookingId}`, {
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.data.id, bookingId);
});

// 17. Driver booking details
test('17. Driver can view booking details for their ride (200)', async () => {
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
  const bookingId = (await createRes.json()).data.id;

  const res = await fetch(`${baseUrl}/bookings/${bookingId}`, {
    headers: { Authorization: `Bearer ${driverToken}` },
  });
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.data.id, bookingId);
});

// 18. Cancellation
test('18. Passenger cancels pending booking, transitions status to cancelled', async () => {
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
  const bookingId = (await createRes.json()).data.id;

  const cancelRes = await fetch(`${baseUrl}/bookings/${bookingId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(cancelRes.status, 200);
  const cancelJson = await cancelRes.json();
  assert.strictEqual(cancelJson.data.status, 'cancelled');
});

// 19. Cancellation releases capacity
test('19. Cancellation releases reserved seats back to ride capacity', async () => {
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
  const bookingId = (await createRes.json()).data.id;

  // Verify ride capacity decremented to 1
  let ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 1);

  // Cancel booking
  await fetch(`${baseUrl}/bookings/${bookingId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });

  // Capacity restored back to 3
  ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 3);
});

// 20. Concurrent booking requests cannot overbook
test('20. Concurrent booking requests from different passengers cannot overbook remaining capacity', async () => {
  // activeRide has 3 available seats. Passenger A requests 2 seats, Passenger B (thirdParty) requests 2 seats concurrently.
  // Exactly one request must succeed (201) and the other must fail (409).
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

// 21. Concurrent same-passenger requests cannot create duplicate active bookings
test('21. Concurrent same-passenger requests cannot create duplicate active bookings', async () => {
  // Same passenger fires 2 concurrent requests for the same ride.
  // Exactly one must succeed (201) and one must fail (409), and available seats must decrement only once.
  const [res1, res2] = await Promise.all([
    fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        rideId: activeRide._id.toString(),
        requestedSeats: 1,
      }),
    }),
    fetch(`${baseUrl}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        rideId: activeRide._id.toString(),
        requestedSeats: 1,
      }),
    }),
  ]);

  const statuses = [res1.status, res2.status].sort();
  assert.deepStrictEqual(statuses, [201, 409]);

  const activeBookings = await Booking.find({
    passenger: passengerUser._id,
    ride: activeRide._id,
    status: { $in: ['pending', 'accepted'] },
  });
  assert.strictEqual(activeBookings.length, 1);

  const ride = await Ride.findById(activeRide._id);
  assert.strictEqual(ride.availableSeats, 2); // 3 - 1 = 2
});
