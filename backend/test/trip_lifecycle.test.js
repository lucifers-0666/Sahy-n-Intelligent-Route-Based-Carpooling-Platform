const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer, MongoMemoryReplSet } = require('mongodb-memory-server');
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

let driverA;
let driverAToken;
let vehicleA;

let driverB;
let driverBToken;
let vehicleB;

let passengerUser;
let passengerToken;

let passengerTwo;
let passengerTwoToken;

let testRide;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryReplSet.create({ replSet: { count: 1 } });
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    try {
      mongoServer = await MongoMemoryServer.create();
      const mongoUri = mongoServer.getUri();
      await mongoose.connect(mongoUri);
    } catch (err2) {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_trip_test';
      await mongoose.connect(mongoUri);
    }
  }

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

  // 1. Driver A (Ride owner)
  driverA = await User.create({
    name: 'Harsh Dave',
    email: 'harsh.lifecycle@example.com',
    phone: '+919876541101',
    password: 'Password123@#',
    city: 'Bhuj',
    isVerified: true,
  });
  driverAToken = jwt.sign({ id: driverA._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  vehicleA = await Vehicle.create({
    owner: driverA._id,
    registrationNumber: 'GJ12AA1101',
    vehicleType: 'sedan',
    make: 'Honda',
    model: 'City',
    year: 2022,
    color: 'White',
    seatCapacity: 4,
    status: 'active',
  });

  // 2. Driver B (Unrelated driver)
  driverB = await User.create({
    name: 'Karan Patel',
    email: 'karan.lifecycle@example.com',
    phone: '+919876541102',
    password: 'Password123@#',
    city: 'Rajkot',
    isVerified: true,
  });
  driverBToken = jwt.sign({ id: driverB._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  vehicleB = await Vehicle.create({
    owner: driverB._id,
    registrationNumber: 'GJ03BB2102',
    vehicleType: 'hatchback',
    make: 'Maruti',
    model: 'Swift',
    year: 2021,
    color: 'Red',
    seatCapacity: 4,
    status: 'active',
  });

  // 3. Passenger 1
  passengerUser = await User.create({
    name: 'Priya Sharma',
    email: 'priya.lifecycle@example.com',
    phone: '+919876541103',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // 4. Passenger 2
  passengerTwo = await User.create({
    name: 'Aakash Verma',
    email: 'aakash.lifecycle@example.com',
    phone: '+919876541104',
    password: 'Password123@#',
    city: 'Gandhidham',
    isVerified: true,
  });
  passengerTwoToken = jwt.sign({ id: passengerTwo._id.toString() }, getJwtSecret(), { expiresIn: '1h' });
});

test.beforeEach(async () => {
  await Booking.deleteMany({});
  await Ride.deleteMany({});

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(9, 30, 0, 0);

  testRide = await Ride.create({
    driver: driverA._id,
    vehicle: vehicleA._id,
    origin: {
      name: 'Bhuj Jubilee Ground',
      latitude: 23.242,
      longitude: 69.6669,
      point: { type: 'Point', coordinates: [69.6669, 23.242] },
    },
    destination: {
      name: 'Ahmedabad Iscon',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    route: {
      encodedPolyline: 'mock_polyline',
      distanceMeters: 380000,
      durationSeconds: 21600,
    },
    departureTime: tomorrow,
    estimatedArrivalTime: new Date(tomorrow.getTime() + 6 * 3600 * 1000),
    totalSeats: 4,
    availableSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 450,
    pickupPolicy: 'nearby',
    amenities: ['AC', 'Music'],
    notes: 'Starting on time',
    status: 'scheduled',
  });
});

test.after(async () => {
  if (server) server.close();
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  if (mongoServer) {
    await mongoServer.stop();
  }
});

async function createPendingBooking(passengerTokenToUse, seats = 1) {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerTokenToUse}`,
    },
    body: JSON.stringify({
      rideId: testRide._id.toString(),
      requestedSeats: seats,
      passengerNote: 'Leaving early',
      pickup: {
        name: 'Bhuj Station',
        latitude: 23.25,
        longitude: 69.67,
      },
      drop: {
        name: 'Ahmedabad Paldi',
        latitude: 23.01,
        longitude: 72.56,
      },
    }),
  });
  return await res.json();
}

test('1. Scheduled initial state', async () => {
  const res = await fetch(`${baseUrl}/rides/${testRide._id}`);
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.ride.status, 'scheduled');
});

test('2. Driver starts passenger boarding with 200', async () => {
  const res = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.status, 'boarding');
});

test('3. Non-owner cannot start boarding (403 Forbidden)', async () => {
  const res = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverBToken}` },
  });
  assert.strictEqual(res.status, 403);
});

test('4. Invalid start boarding transitions (409 Conflict)', async () => {
  // Put ride in boarding
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'boarding' } });
  const res1 = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res1.status, 409);

  // Put ride in active
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'active' } });
  const res2 = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res2.status, 409);

  // Put ride in completed
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'completed' } });
  const res3 = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res3.status, 409);

  // Put ride in cancelled
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'cancelled' } });
  const res4 = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res4.status, 409);
});

test('5. Boarding -> Active trip succeeds with 200', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'boarding' } });

  const res = await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.status, 'active');
});

test('6. Non-owner cannot start trip (403 Forbidden)', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'boarding' } });

  const res = await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverBToken}` },
  });
  assert.strictEqual(res.status, 403);
});

test('7. Scheduled cannot directly become active without boarding (409 Conflict)', async () => {
  const res = await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.ok(data.message.includes('boarding'));
});

test('8. Active -> Completed trip succeeds with 200', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'active' } });

  const res = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.status, 'completed');
});

test('9. Non-owner cannot complete trip (403 Forbidden)', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'active' } });

  const res = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverBToken}` },
  });
  assert.strictEqual(res.status, 403);
});

test('10. Completed cannot become active, boarding, or scheduled (409)', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'completed' } });

  const resStart = await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resStart.status, 409);

  const resBoarding = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resBoarding.status, 409);

  const resComplete = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resComplete.status, 409);
});

test('11. Cancelled ride cannot restart (start-boarding, start, complete return 409)', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'cancelled' } });

  const resBoarding = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resBoarding.status, 409);

  const resStart = await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resStart.status, 409);

  const resComplete = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resComplete.status, 409);
});

test('12. Scheduled -> Cancelled succeeds with 200', async () => {
  const res = await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.ride.status, 'cancelled');
});

test('13. Boarding -> Cancelled succeeds with 200', async () => {
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'boarding' } });

  const res = await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.ride.status, 'cancelled');
});

test('14. Invalid cancellation: cannot cancel active trip or completed ride (409)', async () => {
  // Active
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'active' } });
  const resActive = await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(resActive.status, 409);
  const dataActive = await resActive.json();
  assert.ok(dataActive.message.includes('active trip'));

  // Completed
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'completed' } });
  const resCompleted = await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.ok(resCompleted.status === 400 || resCompleted.status === 409);
});

test('15. Cancelled ride cannot accept booking (409 Conflict)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Cancel ride
  await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Attempt to accept
  const acceptRes = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(acceptRes.status, 409);
});

test('16. Completed ride cannot accept booking (409 Conflict)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Manually put ride in active then complete
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'active' } });
  await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Attempt to accept
  const acceptRes = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(acceptRes.status, 409);
});

test('17. Trip completion updates accepted bookings to completed', async () => {
  // Passenger requests and driver accepts
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Transition ride to boarding then active
  await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Driver completes trip
  const completeRes = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(completeRes.status, 200);

  // Booking in DB must now be completed
  const updatedBooking = await Booking.findById(bookingId);
  assert.strictEqual(updatedBooking.status, 'completed');
});

test('18. Trip completion rejects lingering pending bookings', async () => {
  // Passenger 1 accepted
  const booking1Res = await createPendingBooking(passengerToken, 1);
  const booking1Id = booking1Res.data.id;
  await fetch(`${baseUrl}/bookings/${booking1Id}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Passenger 2 requests but remains pending
  const booking2Res = await createPendingBooking(passengerTwoToken, 1);
  const booking2Id = booking2Res.data.id;

  // Transition ride to boarding then active then completed
  await Ride.findByIdAndUpdate(testRide._id, { $set: { status: 'active' } });
  const completeRes = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(completeRes.status, 200);

  // Accepted booking becomes completed
  const b1 = await Booking.findById(booking1Id);
  assert.strictEqual(b1.status, 'completed');

  // Lingering pending booking is rejected
  const b2 = await Booking.findById(booking2Id);
  assert.strictEqual(b2.status, 'rejected');
});

test('19. Cancellation releases pending seat reservations and marks bookings cancelled', async () => {
  // Pending booking for 2 seats
  const bookingRes = await createPendingBooking(passengerToken, 2);
  const bookingId = bookingRes.data.id;

  // Available seats were 2
  let ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);

  // Driver cancels ride
  const cancelRes = await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(cancelRes.status, 200);

  // Booking is marked cancelled
  const booking = await Booking.findById(bookingId);
  assert.strictEqual(booking.status, 'cancelled');

  // Ride capacity is restored
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.status, 'cancelled');
  assert.strictEqual(ride.availableSeats, 4);
  assert.strictEqual(ride.bookedSeats, 0);
});

test('20. Capacity is preserved across boarding, active, and completed transitions', async () => {
  // Passenger requests 2 seats and driver accepts
  const bookingRes = await createPendingBooking(passengerToken, 2);
  const bookingId = bookingRes.data.id;
  await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Capacity after accept: available = 2, booked = 2
  let ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 2);

  // Start boarding
  await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 2);

  // Start trip
  await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 2);

  // Complete trip
  await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 2);
});

test('21. Concurrency protection: duplicate start-boarding or conflicting actions', async () => {
  // Concurrent start boarding and cancel
  const [res1, res2] = await Promise.all([
    fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${driverAToken}` },
    }),
    fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${driverAToken}` },
    }),
  ]);

  const statuses = [res1.status, res2.status];
  assert.ok(statuses.includes(200));

  const ride = await Ride.findById(testRide._id);
  assert.ok(ride.status === 'boarding' || ride.status === 'cancelled');
});

test('22. Unauthorized passenger cannot modify ride lifecycle (403)', async () => {
  const resBoarding = await fetch(`${baseUrl}/rides/${testRide._id}/start-boarding`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(resBoarding.status, 403);

  const resStart = await fetch(`${baseUrl}/rides/${testRide._id}/start`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(resStart.status, 403);

  const resComplete = await fetch(`${baseUrl}/rides/${testRide._id}/complete`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(resComplete.status, 403);

  const resCancel = await fetch(`${baseUrl}/rides/${testRide._id}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(resCancel.status, 403);
});
