const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');
const Report = require('../src/models/Report');
const AuditLog = require('../src/models/AuditLog');
const PaymentTransaction = require('../src/models/PaymentTransaction');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;
let adminUser;
let adminToken;

test.before(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  adminUser = await User.create({
    name: 'Super Administrator',
    email: 'superadmin@sahyan.app',
    phone: '+919999900001',
    password: 'Password123!',
    role: 'super_admin',
    isVerified: true,
  });
  adminToken = jwt.sign({ id: adminUser._id, role: adminUser.role }, getJwtSecret(), { expiresIn: '1h' });

  server = app.listen(0);
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}`;
});

test.after(async () => {
  if (server) await server.close();
  if (mongoose.connection.readyState !== 0) await mongoose.connection.close();
  if (mongoServer) await mongoServer.stop();
});

test('Audit all GET admin endpoints', async () => {
  const endpoints = [
    '/api/v1/admin/stats',
    '/api/v1/admin/users',
    '/api/v1/admin/users?status=pending',
    '/api/v1/admin/users?status=all&limit=100',
    '/api/v1/admin/rides',
    '/api/v1/admin/rides?status=all&limit=100',
    '/api/v1/admin/bookings',
    '/api/v1/admin/bookings?status=all&limit=100',
    '/api/v1/admin/reports',
    '/api/v1/admin/reports?status=all&limit=100',
    '/api/v1/admin/audit-logs',
    '/api/v1/admin/audit-logs?page=1&limit=20',
    '/api/v1/admin/revenue-stats',
    '/api/v1/admin/config',
    '/api/v1/admin/disputes',
    '/api/v1/admin/fraud/signals',
    '/api/v1/admin/appeals',
  ];

  for (const ep of endpoints) {
    const res = await fetch(`${baseUrl}${ep}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    console.log(`Endpoint ${ep} returned status: ${res.status}`);
    const body = await res.json();
    assert.strictEqual(res.status, 200, `Failed on ${ep}: ${JSON.stringify(body)}`);
    assert.strictEqual(body.success, true, `Expected success true on ${ep}`);
  }
});
