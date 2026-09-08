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
      const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_driver_test';
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
    email: 'harsh.driver@example.com',
    phone: '+919876541001',
    password: 'Password123@#',
    city: 'Bhuj',
    isVerified: true,
  });
  driverAToken = jwt.sign({ id: driverA._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  vehicleA = await Vehicle.create({
    owner: driverA._id,
    registrationNumber: 'GJ12AA1001',
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
    email: 'karan.driver@example.com',
    phone: '+919876541002',
    password: 'Password123@#',
    city: 'Rajkot',
    isVerified: true,
  });
  driverBToken = jwt.sign({ id: driverB._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  vehicleB = await Vehicle.create({
    owner: driverB._id,
    registrationNumber: 'GJ03BB2002',
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
    email: 'priya.passenger@example.com',
    phone: '+919876541003',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passengerUser._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // 4. Passenger 2
  passengerTwo = await User.create({
    name: 'Aakash Verma',
    email: 'aakash.passenger@example.com',
    phone: '+919876541004',
    password: 'Password123@#',
    city: 'Gandhidham',
    isVerified: true,
  });
  passengerTwoToken = jwt.sign({ id: passengerTwo._id.toString() }, getJwtSecret(), { expiresIn: '1h' });
});

test.beforeEach(async () => {
  await Booking.deleteMany({});
  await Ride.deleteMany({});

  // Seed standard scheduled ride owned by Driver A
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

// Helper to create a pending booking
async function createPendingBooking(passengerTokenToUse, seats = 1, note = 'Leaving early') {
  const res = await fetch(`${baseUrl}/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${passengerTokenToUse}`,
    },
    body: JSON.stringify({
      rideId: testRide._id.toString(),
      requestedSeats: seats,
      passengerNote: note,
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

test('1. Unauthenticated driver request access rejected with 401', async () => {
  const res = await fetch(`${baseUrl}/bookings/driver/requests`);
  assert.strictEqual(res.status, 401);
});

test('2. Non-driver unrelated user cannot access requests for specific ride (403)', async () => {
  const res = await fetch(`${baseUrl}/bookings/driver/requests?rideId=${testRide._id}`, {
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(res.status, 403);
  const data = await res.json();
  assert.strictEqual(data.success, false);
});

test('3. Real ride owner driver can view requests (200)', async () => {
  await createPendingBooking(passengerToken, 2);

  const res = await fetch(`${baseUrl}/bookings/driver/requests`, {
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.count, 1);
  assert.strictEqual(data.data[0].requestedSeats, 2);
  assert.strictEqual(data.data[0].passenger.name, 'Priya Sharma');
});

test('4. Unrelated driver B cannot view requests for Driver A ride (403)', async () => {
  await createPendingBooking(passengerToken, 1);

  const res = await fetch(`${baseUrl}/bookings/driver/requests?rideId=${testRide._id}`, {
    headers: { Authorization: `Bearer ${driverBToken}` },
  });
  assert.strictEqual(res.status, 403);
});

test('5. Pending request is returned with correct status and populated public info', async () => {
  await createPendingBooking(passengerToken, 1, 'Near bus stand');

  const res = await fetch(`${baseUrl}/bookings/driver/requests?status=pending`, {
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.count, 1);
  const booking = data.data[0];
  assert.strictEqual(booking.status, 'pending');
  assert.strictEqual(booking.passengerNote, 'Near bus stand');
  assert.ok(booking.passenger.name);
  assert.ok(booking.passenger.phone);
  assert.strictEqual(booking.passenger.password, undefined);
});

test('6. Driver can accept pending request successfully', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 2);
  const bookingId = bookingRes.data.id;

  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.data.status, 'accepted');

  // Verify in database
  const updated = await Booking.findById(bookingId);
  assert.strictEqual(updated.status, 'accepted');
});

test('7. Cannot accept an already accepted request twice (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Accept first time
  await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Accept second time
  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.match(data.message, /already accepted/i);
});

test('8. Cannot accept a rejected request (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Reject first
  await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Try to accept
  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.match(data.message, /cannot accept a rejected/i);
});

test('9. Cannot accept a cancelled booking request (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Passenger cancels
  await fetch(`${baseUrl}/bookings/${bookingId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });

  // Driver tries to accept
  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
});

test('10. Cannot accept booking on a cancelled ride (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Mark ride cancelled
  await Ride.findByIdAndUpdate(testRide._id, { status: 'cancelled' });

  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.match(data.message, /cancelled ride/i);
});

test('11. Cannot accept booking on a completed ride (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Mark ride completed
  await Ride.findByIdAndUpdate(testRide._id, { status: 'completed' });

  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.match(data.message, /completed ride/i);
});

test('12. Cannot accept booking on a departed ride (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Set departureTime in past
  const past = new Date(Date.now() - 3600 * 1000);
  await Ride.findByIdAndUpdate(testRide._id, { departureTime: past });

  const res = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.match(data.message, /departed/i);
});

test('13. Driver can reject a pending booking request', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  const res = await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.data.status, 'rejected');

  const inDb = await Booking.findById(bookingId);
  assert.strictEqual(inDb.status, 'rejected');
});

test('14. Cannot reject an already accepted request (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Accept
  await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Try to reject
  const res = await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 409);
  const data = await res.json();
  assert.match(data.message, /already accepted/i);
});

test('15. Rejection releases reserved seats back to ride capacity', async () => {
  // Before request: totalSeats = 4, availableSeats = 4
  const bookingRes = await createPendingBooking(passengerToken, 2);
  const bookingId = bookingRes.data.id;

  // After request: availableSeats should be 2
  let ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);

  // Driver rejects request
  await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Seats should be released back: availableSeats = 4
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 4);
  assert.strictEqual(ride.bookedSeats, 0);
});

test('16. Acceptance keeps capacity consistent: bookedSeats increments, availableSeats NOT decremented twice', async () => {
  // Request 2 seats: availableSeats becomes 2, bookedSeats is 0
  const bookingRes = await createPendingBooking(passengerToken, 2);
  const bookingId = bookingRes.data.id;

  let ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 0);

  // Driver accepts request
  await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // After accept: availableSeats remains 2 (was already decremented), bookedSeats becomes 2
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 2);
  assert.strictEqual(ride.totalSeats, 4);
});

test('17. Multiple pending requests maintain exact capacity invariant through accept and reject', async () => {
  // Passenger 1 requests 2 seats -> available = 2
  const b1 = await createPendingBooking(passengerToken, 2);
  // Passenger 2 requests 2 seats -> available = 0
  const b2 = await createPendingBooking(passengerTwoToken, 2);

  let ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 0);
  assert.strictEqual(ride.bookedSeats, 0);

  // Driver accepts Passenger 1
  await fetch(`${baseUrl}/bookings/${b1.data.id}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 0);
  assert.strictEqual(ride.bookedSeats, 2);

  // Driver rejects Passenger 2
  await fetch(`${baseUrl}/bookings/${b2.data.id}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2); // 2 seats released back!
  assert.strictEqual(ride.bookedSeats, 2); // Passenger 1 seats remain booked!
  assert.strictEqual(ride.availableSeats + ride.bookedSeats, ride.totalSeats);
});

test('18. Passenger sees accepted status in their booking list and details', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Accept
  await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Passenger fetches own bookings
  const res = await fetch(`${baseUrl}/bookings/my`, {
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  const data = await res.json();
  const passengerBooking = data.data.find((b) => b.id === bookingId);
  assert.strictEqual(passengerBooking.status, 'accepted');
});

test('19. Passenger sees rejected status in their booking list', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Reject
  await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });

  // Passenger fetches own bookings
  const res = await fetch(`${baseUrl}/bookings/my`, {
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  const data = await res.json();
  const passengerBooking = data.data.find((b) => b.id === bookingId);
  assert.strictEqual(passengerBooking.status, 'rejected');
});

test('20. Passenger cannot accept or reject booking requests (403)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Passenger attempts to accept
  const acceptRes = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(acceptRes.status, 403);

  // Passenger attempts to reject
  const rejectRes = await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${passengerToken}` },
  });
  assert.strictEqual(rejectRes.status, 403);
});

test('21. Concurrency protection: simultaneous accept and reject resolved deterministically', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 2);
  const bookingId = bookingRes.data.id;

  // Send accept and reject concurrently
  const [res1, res2] = await Promise.all([
    fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${driverAToken}` },
    }),
    fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${driverAToken}` },
    }),
  ]);

  const statuses = [res1.status, res2.status];
  // Exactly one must succeed (200) and one must be conflict (409)
  assert.ok(statuses.includes(200));
  assert.ok(statuses.includes(409));

  // Capacity must be strictly valid in DB
  const ride = await Ride.findById(testRide._id);
  const finalBooking = await Booking.findById(bookingId);

  if (finalBooking.status === 'accepted') {
    assert.strictEqual(ride.availableSeats, 2);
    assert.strictEqual(ride.bookedSeats, 2);
  } else {
    assert.strictEqual(finalBooking.status, 'rejected');
    assert.strictEqual(ride.availableSeats, 4);
    assert.strictEqual(ride.bookedSeats, 0);
  }
});

test('22. Driver request list validates status parameter (400 for invalid)', async () => {
  const res = await fetch(`${baseUrl}/bookings/driver/requests?status=invalid_status`, {
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.ok(data.message.includes('Invalid status filter'));
});

test('23. Driver request list validates page and limit parameters (400 for invalid)', async () => {
  const res1 = await fetch(`${baseUrl}/bookings/driver/requests?page=0`, {
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res1.status, 400);

  const res2 = await fetch(`${baseUrl}/bookings/driver/requests?limit=-5`, {
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(res2.status, 400);
});

test('24. Cannot accept or reject an already completed booking (409)', async () => {
  const bookingRes = await createPendingBooking(passengerToken, 1);
  const bookingId = bookingRes.data.id;

  // Mark completed in DB
  await Booking.findByIdAndUpdate(bookingId, { $set: { status: 'completed' } });

  const acceptRes = await fetch(`${baseUrl}/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(acceptRes.status, 409);

  const rejectRes = await fetch(`${baseUrl}/bookings/${bookingId}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(rejectRes.status, 409);
});

test('25. Multi-passenger capacity test: Accept A and Reject B maintains exact capacity', async () => {
  // testRide is created in test.beforeEach with capacity = 4, availableSeats = 4, bookedSeats = 0

  // Passenger A requests 2 seats
  const bookingARes = await createPendingBooking(passengerToken, 2);
  const bookingA = bookingARes.data;

  // Passenger B requests 2 seats
  const bookingBRes = await createPendingBooking(passengerTwoToken, 2);
  const bookingB = bookingBRes.data;

  // Check state: available = 0, booked = 0
  let ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 0);
  assert.strictEqual(ride.bookedSeats, 0);

  // Driver accepts A
  const acceptA = await fetch(`${baseUrl}/bookings/${bookingA.id}/accept`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(acceptA.status, 200);

  // State after accepting A: available = 0, booked = 2
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 0);
  assert.strictEqual(ride.bookedSeats, 2);

  // Driver rejects B
  const rejectB = await fetch(`${baseUrl}/bookings/${bookingB.id}/reject`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${driverAToken}` },
  });
  assert.strictEqual(rejectB.status, 200);

  // State after rejecting B: available = 2, booked = 2
  ride = await Ride.findById(testRide._id);
  assert.strictEqual(ride.availableSeats, 2);
  assert.strictEqual(ride.bookedSeats, 2);
});

