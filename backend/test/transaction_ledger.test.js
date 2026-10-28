const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Booking = require('../src/models/Booking');
const Ride = require('../src/models/Ride');
const PaymentTransaction = require('../src/models/PaymentTransaction');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;
let passenger;
let driver;
let superAdmin;
let regularAdmin;
let passengerToken;
let driverToken;
let superAdminToken;
let regularAdminToken;

test.before(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  passenger = await User.create({
    name: 'Aarav Mehta',
    email: 'aarav@example.com',
    phone: '+919876500001',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
  });
  passengerToken = jwt.sign({ id: passenger._id, role: passenger.role }, getJwtSecret(), { expiresIn: '1h' });

  driver = await User.create({
    name: 'Vikram Sharma',
    email: 'vikram@example.com',
    phone: '+919876500002',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
    capabilities: { canDrive: true },
  });
  driverToken = jwt.sign({ id: driver._id, role: driver.role }, getJwtSecret(), { expiresIn: '1h' });

  superAdmin = await User.create({
    name: 'Super Admin',
    email: 'superadmin@sahyan.internal',
    phone: '+919876500003',
    password: 'Password123!',
    role: 'super_admin',
    isVerified: true,
  });
  superAdminToken = jwt.sign({ id: superAdmin._id, role: superAdmin.role }, getJwtSecret(), { expiresIn: '1h' });

  regularAdmin = await User.create({
    name: 'Ops Admin',
    email: 'ops@sahyan.internal',
    phone: '+919876500004',
    password: 'Password123!',
    role: 'admin',
    isVerified: true,
  });
  regularAdminToken = jwt.sign({ id: regularAdmin._id, role: regularAdmin.role }, getJwtSecret(), { expiresIn: '1h' });

  // Seed sample vehicle, ride & booking
  const vehicle = await Vehicle.create({
    owner: driver._id,
    make: 'Hyundai',
    model: 'i20',
    year: 2022,
    color: 'White',
    licensePlate: 'GJ-01-AB-1234',
    totalSeats: 4,
    seatCapacity: 4,
    vehicleType: 'hatchback',
    registrationNumber: 'GJ01AB1234',
    verified: true,
  });

  const depTime = new Date(Date.now() + 86400000);
  const arrTime = new Date(Date.now() + 90000000);

  const ride = await Ride.create({
    driver: driver._id,
    vehicle: vehicle._id,
    origin: {
      name: 'Ahmedabad ISKCON',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    destination: {
      name: 'Vadodara Central',
      latitude: 22.3072,
      longitude: 73.1812,
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    route: {
      encodedPolyline: 'g}weD_qhyM~@_@b@_@|@e@',
      distanceMeters: 110000,
      durationSeconds: 7200,
    },
    departureTime: depTime,
    estimatedArrivalTime: arrTime,
    totalSeats: 3,
    availableSeats: 2,
    contributionPerSeat: 250,
    status: 'scheduled',
  });

  const booking = await Booking.create({
    ride: ride._id,
    passenger: passenger._id,
    driver: driver._id,
    requestedSeats: 1,
    totalContribution: 250,
    contributionPerSeat: 250,
    pickup: ride.origin,
    drop: ride.destination,
    status: 'accepted',
    paymentStatus: 'paid',
    paymentMethod: 'upi',
  });

  // Seed transactions
  await PaymentTransaction.create({
    bookingId: booking._id,
    passengerId: passenger._id,
    driverId: driver._id,
    amount: 250,
    platformFee: 15,
    paymentMethod: 'upi',
    status: 'escrow_held',
    isSandbox: true,
    gatewayOrderId: 'order_test_101',
    gatewayReference: 'pay_test_ref_101',
    verifiedBy: 'sandbox_mock',
  });

  server = app.listen(0);
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}`;
});

test.after(async () => {
  if (server) await server.close();
  if (mongoose.connection.readyState !== 0) await mongoose.connection.close();
  if (mongoServer) await mongoServer.stop();
});

test('Transaction Ledger, Telemetry, and Role Management Tests', async (t) => {
  await t.test('1. Passenger retrieves their transaction history', async () => {
    const res = await fetch(`${baseUrl}/api/v1/payments/my-transactions`, {
      headers: { Authorization: `Bearer ${passengerToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(json.data.length, 1);
    assert.strictEqual(json.data[0].amount, 250);
    assert.strictEqual(json.data[0].status, 'escrow_held');
    assert.strictEqual(json.metrics.escrowHeld, 250);
  });

  await t.test('2. Driver also sees the transaction as beneficiary/payee', async () => {
    const res = await fetch(`${baseUrl}/api/v1/payments/my-transactions`, {
      headers: { Authorization: `Bearer ${driverToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.data.length, 1);
  });

  await t.test('3. Admin retrieves transactions ledger with volume aggregates', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/transactions?status=all`, {
      headers: { Authorization: `Bearer ${superAdminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(json.data.length, 1);
    assert.strictEqual(json.metrics.totalVolume, 250);
    assert.strictEqual(json.metrics.platformFees, 15);
    assert.strictEqual(json.metrics.sandboxCount, 1);
  });

  await t.test('4. System health telemetry reports database and subsystem metrics', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/system/health-telemetry`, {
      headers: { Authorization: `Bearer ${superAdminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(json.data.database.status, 'healthy');
    assert.ok(typeof json.data.uptimeSeconds === 'number');
    assert.ok(typeof json.data.memory.rssMb === 'number');
  });

  await t.test('5. Role management: Super Admin updates user role', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/${driver._id}/role`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${superAdminToken}`,
      },
      body: JSON.stringify({ role: 'safety_officer' }),
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.data.role, 'safety_officer');

    const updated = await User.findById(driver._id);
    assert.strictEqual(updated.role, 'safety_officer');
  });

  await t.test('6. Role management: Non-super-admin is blocked with 403', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/${driver._id}/role`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${regularAdminToken}`,
      },
      body: JSON.stringify({ role: 'admin' }),
    });
    assert.strictEqual(res.status, 403);
  });

  await t.test('7. Role management: Super Admin cannot modify self', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/${superAdmin._id}/role`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${superAdminToken}`,
      },
      body: JSON.stringify({ role: 'user' }),
    });
    assert.strictEqual(res.status, 403);
  });
});
