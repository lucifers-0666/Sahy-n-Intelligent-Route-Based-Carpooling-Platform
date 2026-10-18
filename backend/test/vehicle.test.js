const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;

let userA;
let tokenA;
let userB;
let tokenB;

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

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  // Create User A
  userA = await User.create({
    name: 'Aarav Mehta',
    email: 'aarav.driver@example.com',
    phone: '+919876500001',
    password: 'Password123@#',
    city: 'Ahmedabad',
    isVerified: true,
  });
  tokenA = jwt.sign({ id: userA._id.toString() }, getJwtSecret(), { expiresIn: '1h' });

  // Create User B
  userB = await User.create({
    name: 'Diya Shah',
    email: 'diya.driver@example.com',
    phone: '+919876500002',
    password: 'Password123@#',
    city: 'Gandhinagar',
    isVerified: true,
  });
  tokenB = jwt.sign({ id: userB._id.toString() }, getJwtSecret(), { expiresIn: '1h' });
});

test.after(async () => {
  await Vehicle.deleteMany({});
  await User.deleteMany({});
  await mongoose.connection.close();
  if (mongoServer) {
    await mongoServer.stop();
  }
  server.close();
});

test('VEHICLES: Unauthenticated requests are rejected with 401', async () => {
  const getRes = await fetch(`${baseUrl}/vehicles`);
  assert.strictEqual(getRes.status, 401);

  const postRes = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ make: 'Honda' }),
  });
  assert.strictEqual(postRes.status, 401);
});

test('VEHICLES: Initial list for User A is empty', async () => {
  const res = await fetch(`${baseUrl}/vehicles`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.count, 0);
  assert.strictEqual(data.vehicles.length, 0);
});

test('VEHICLES: Create vehicle with missing or invalid fields is rejected with 400', async () => {
  // 1. Missing fields
  const missingRes = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      make: 'Maruti Suzuki',
      model: 'Swift',
    }),
  });
  assert.strictEqual(missingRes.status, 400);

  // 2. Invalid vehicle type
  const invalidTypeRes = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'aeroplane',
      make: 'Boeing',
      model: '747',
      year: 2022,
      color: 'White',
      seatCapacity: 4,
    }),
  });
  assert.strictEqual(invalidTypeRes.status, 400);

  // 3. Invalid seat capacity (0, negative, > 8, or decimal)
  const zeroSeatRes = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift',
      year: 2022,
      color: 'Red',
      seatCapacity: 0,
    }),
  });
  assert.strictEqual(zeroSeatRes.status, 400);

  const nineSeatRes = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift',
      year: 2022,
      color: 'Red',
      seatCapacity: 9,
    }),
  });
  assert.strictEqual(nineSeatRes.status, 400);

  // 4. Invalid Year (< 1990 or > currentYear + 1)
  const oldYearRes = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift',
      year: 1985,
      color: 'Red',
      seatCapacity: 4,
    }),
  });
  assert.strictEqual(oldYearRes.status, 400);
});

let vehicleAId;

test('VEHICLES: Create vehicle successfully normalizes registration and advances onboarding status', async () => {
  const initialUser = await User.findById(userA._id);
  assert.strictEqual(initialUser.capabilities.canDrive, false);
  assert.strictEqual(initialUser.driverProfile.onboardingStatus, 'not_started');

  const payload = {
    registrationNumber: 'gj 01 ab 1234', // Needs normalization to GJ01AB1234
    vehicleType: 'hatchback',
    make: 'Maruti Suzuki',
    model: 'Swift VXI',
    year: 2023,
    color: 'Arctic White',
    seatCapacity: 4,
  };

  const res = await fetch(`${baseUrl}/vehicles`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify(payload),
  });

  assert.strictEqual(res.status, 201);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.vehicle.registrationNumber, 'GJ01AB1234');
  assert.strictEqual(data.vehicle.make, 'Maruti Suzuki');
  assert.strictEqual(data.vehicle.model, 'Swift VXI');
  assert.strictEqual(data.vehicle.seatCapacity, 4);
  assert.strictEqual(data.vehicle.owner, userA._id.toString());
  assert.strictEqual(data.vehicle.status, 'active');

  vehicleAId = data.vehicle.id || data.vehicle._id;
  assert.ok(vehicleAId);

  // Verify onboarding status transition on User model
  const updatedUser = await User.findById(userA._id);
  assert.strictEqual(updatedUser.capabilities.canDrive, false);
  assert.strictEqual(updatedUser.driverProfile.onboardingStatus, 'in_progress');
});

test('VEHICLES: Rejects duplicate registration number (case and whitespace insensitive)', async () => {
  const duplicatePayload = {
    registrationNumber: 'GJ01 AB 1234', // Identical when normalized
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
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify(duplicatePayload),
  });

  assert.strictEqual(res.status, 400);
  const data = await res.json();
  assert.strictEqual(data.success, false);
  assert.match(data.message, /already registered/i);
});

test('VEHICLES: User A can fetch list and individual vehicle details', async () => {
  const listRes = await fetch(`${baseUrl}/vehicles`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(listRes.status, 200);
  const listData = await listRes.json();
  assert.strictEqual(listData.count, 1);
  assert.strictEqual(listData.vehicles[0].registrationNumber, 'GJ01AB1234');

  const singleRes = await fetch(`${baseUrl}/vehicles/${vehicleAId}`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(singleRes.status, 200);
  const singleData = await singleRes.json();
  assert.strictEqual(singleData.vehicle.registrationNumber, 'GJ01AB1234');
  assert.strictEqual(singleData.vehicle.make, 'Maruti Suzuki');
});

test('VEHICLES: User A can update vehicle details', async () => {
  const updatePayload = {
    color: 'Midnight Blue',
    seatCapacity: 3,
    model: 'Swift ZXI+',
  };

  const res = await fetch(`${baseUrl}/vehicles/${vehicleAId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify(updatePayload),
  });

  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.vehicle.color, 'Midnight Blue');
  assert.strictEqual(data.vehicle.seatCapacity, 3);
  assert.strictEqual(data.vehicle.model, 'Swift ZXI+');
});

test('SECURITY & CROSS-USER ISOLATION: User B cannot access, modify, or delete User A vehicle', async () => {
  // 1. User B cannot read User A's vehicle
  const getRes = await fetch(`${baseUrl}/vehicles/${vehicleAId}`, {
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  assert.strictEqual(getRes.status, 403);
  const getData = await getRes.json();
  assert.strictEqual(getData.success, false);

  // 2. User B's vehicle list does NOT contain User A's vehicle
  const listRes = await fetch(`${baseUrl}/vehicles`, {
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  assert.strictEqual(listRes.status, 200);
  const listData = await listRes.json();
  assert.strictEqual(listData.count, 0);

  // 3. User B cannot update User A's vehicle
  const updateRes = await fetch(`${baseUrl}/vehicles/${vehicleAId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify({ make: 'HackedMake' }),
  });
  assert.strictEqual(updateRes.status, 403);

  // 4. User B cannot delete User A's vehicle
  const deleteRes = await fetch(`${baseUrl}/vehicles/${vehicleAId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  assert.strictEqual(deleteRes.status, 403);
});

test('VEHICLES: Delete vehicle removes it and updates driver capability when 0 vehicles remain', async () => {
  const deleteRes = await fetch(`${baseUrl}/vehicles/${vehicleAId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(deleteRes.status, 200);
  const deleteData = await deleteRes.json();
  assert.strictEqual(deleteData.success, true);
  assert.strictEqual(deleteData.remainingVehicles, 0);

  // Verify User A driver capability resets when 0 vehicles remain
  const user = await User.findById(userA._id);
  assert.strictEqual(user.capabilities.canDrive, false);
  assert.strictEqual(user.driverProfile.onboardingStatus, 'not_started');

  // Verify list is now empty
  const listRes = await fetch(`${baseUrl}/vehicles`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  const listData = await listRes.json();
  assert.strictEqual(listData.count, 0);
});
