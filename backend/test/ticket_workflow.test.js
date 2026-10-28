const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Ticket = require('../src/models/Ticket');
const AuditLog = require('../src/models/AuditLog');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');

let mongoServer;
let server;
let baseUrl;
let regularUser;
let otherUser;
let adminUser;
let userToken;
let otherToken;
let adminToken;

test.before(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  regularUser = await User.create({
    name: 'Kavita Patel',
    email: 'kavita@example.com',
    phone: '+919876543210',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
  });
  userToken = jwt.sign({ id: regularUser._id, role: regularUser.role }, getJwtSecret(), { expiresIn: '1h' });

  otherUser = await User.create({
    name: 'Rahul Joshi',
    email: 'rahul@example.com',
    phone: '+919876543211',
    password: 'Password123!',
    role: 'user',
    isVerified: true,
  });
  otherToken = jwt.sign({ id: otherUser._id, role: otherUser.role }, getJwtSecret(), { expiresIn: '1h' });

  adminUser = await User.create({
    name: 'Admin Specialist',
    email: 'support@sahyan.internal',
    phone: '+919876543212',
    password: 'Password123!',
    role: 'support_lead',
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

test('Support Ticket Lifecycle & Security Tests', async (t) => {
  let createdTicketId;

  await t.test('1. Unauthenticated request to create ticket is rejected with 401', async () => {
    const res = await fetch(`${baseUrl}/api/v1/tickets`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ subject: 'App bug', description: 'Screen froze' }),
    });
    assert.strictEqual(res.status, 401);
  });

  await t.test('2. Valid ticket creation by user returns 201 with ticketNumber', async () => {
    const res = await fetch(`${baseUrl}/api/v1/tickets`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({
        subject: 'Luggage query for Rajkot trip',
        description: 'Can I bring two medium suitcases on the highway corridor trip?',
        category: 'ride_issue',
        priority: 'medium',
      }),
    });
    assert.strictEqual(res.status, 201);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.ok(json.data.ticketNumber.startsWith('TKT-'));
    assert.strictEqual(json.data.status, 'open');
    assert.strictEqual(json.data.messages.length, 1);
    createdTicketId = json.data._id;
  });

  await t.test('3. User can fetch their ticket list', async () => {
    const res = await fetch(`${baseUrl}/api/v1/tickets/my`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(json.data.length, 1);
    assert.strictEqual(json.data[0]._id, createdTicketId);
  });

  await t.test('4. Cross-user isolation: Another user cannot view or reply to ticket', async () => {
    const viewRes = await fetch(`${baseUrl}/api/v1/tickets/${createdTicketId}`, {
      headers: { Authorization: `Bearer ${otherToken}` },
    });
    assert.strictEqual(viewRes.status, 403);

    const replyRes = await fetch(`${baseUrl}/api/v1/tickets/${createdTicketId}/reply`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${otherToken}`,
      },
      body: JSON.stringify({ message: 'Unauthorized intruding message' }),
    });
    assert.strictEqual(replyRes.status, 403);
  });

  await t.test('5. Admin can view ticket and submit reply (transitions to in_progress)', async () => {
    const viewRes = await fetch(`${baseUrl}/api/v1/tickets/${createdTicketId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    assert.strictEqual(viewRes.status, 200);

    const replyRes = await fetch(`${baseUrl}/api/v1/tickets/${createdTicketId}/reply`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        message: 'Hello Kavita, standard policy allows 1 medium bag. Please coordinate with the driver.',
      }),
    });
    assert.strictEqual(replyRes.status, 200);
    const replyJson = await replyRes.json();
    assert.strictEqual(replyJson.data.status, 'in_progress');
    assert.strictEqual(replyJson.data.messages.length, 2);
    assert.strictEqual(replyJson.data.messages[1].sender, 'admin');
  });

  await t.test('6. User can reply back to support team', async () => {
    const res = await fetch(`${baseUrl}/api/v1/tickets/${createdTicketId}/reply`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({ message: 'Understood, thank you for clarifying!' }),
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.data.messages.length, 3);
  });

  await t.test('7. Admin can resolve ticket and record audit trail', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/tickets/${createdTicketId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        status: 'resolved',
        resolutionNotes: 'Clarified luggage dimensions and corridor protocol.',
      }),
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.data.status, 'resolved');

    const audit = await AuditLog.findOne({ action: 'TICKET_UPDATED' });
    assert.ok(audit);
  });

  await t.test('8. Admin ticket queue endpoint returns pagination and counts', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/tickets?status=all`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.ok(json.counts);
    assert.strictEqual(json.counts.resolved, 1);
  });
});

