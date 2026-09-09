const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../src/config/jwt');
const passwordService = require('../src/services/passwordService');

let mongoServer;
let server;
let baseUrl;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    console.log('MongoMemoryServer fallback connecting to local MongoDB...');
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_test';
    await mongoose.connect(mongoUri);
  }

  await User.deleteMany({}); // Clean test db

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;
});

test.after(async () => {
  await User.deleteMany({});
  await mongoose.connection.close();
  if (mongoServer) {
    await mongoServer.stop();
  }
  server.close();
});

test('REGISTRATION: Should register a valid user successfully without returning devOtp or immediate JWT', async () => {
  const payload = {
    name: 'Test Arjun',
    email: 'arjun.test@example.com',
    phone: '9876543210',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 201);
  assert.strictEqual(data.success, true);
  assert.strictEqual(data.user.email, 'arjun.test@example.com');
  assert.strictEqual(data.user.phone, '+919876543210');
  assert.strictEqual(data.user.isVerified, false);
  assert.strictEqual(data.devOtp, undefined); // No devOtp leaked in response
  assert.strictEqual(data.accessToken, undefined); // No JWT bypass before OTP verification
});

test('REGISTRATION: Should reject duplicate email', async () => {
  const payload = {
    name: 'Duplicate User',
    email: 'arjun.test@example.com',
    phone: '9123456789',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /email already exists/i);
});

test('REGISTRATION: Should reject duplicate phone', async () => {
  const payload = {
    name: 'Duplicate Phone User',
    email: 'newemail@example.com',
    phone: '9876543210',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /mobile number already exists/i);
});

test('REGISTRATION: Should reject invalid email format', async () => {
  const payload = {
    name: 'Invalid Email',
    email: 'notanemail',
    phone: '9988776655',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
});

test('REGISTRATION: Should reject weak password (< 8 chars)', async () => {
  const payload = {
    name: 'Short Pass',
    email: 'shortpass@example.com',
    phone: '9988776655',
    password: 'P@1',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /at least 8 characters/i);
});

test('REGISTRATION: Should reject password missing uppercase', async () => {
  const payload = {
    name: 'No Upper',
    email: 'noupper@example.com',
    phone: '9988776656',
    password: 'password123!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /uppercase/i);
});

test('REGISTRATION: Should reject password missing lowercase', async () => {
  const payload = {
    name: 'No Lower',
    email: 'nolower@example.com',
    phone: '9988776657',
    password: 'PASSWORD123!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /lowercase/i);
});

test('REGISTRATION: Should reject password missing number', async () => {
  const payload = {
    name: 'No Number',
    email: 'nonumber@example.com',
    phone: '9988776658',
    password: 'PasswordNoNumber!',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /number/i);
});

test('REGISTRATION: Should reject password missing special character', async () => {
  const payload = {
    name: 'No Special',
    email: 'nospecial@example.com',
    phone: '9988776659',
    password: 'Password1234',
  };

  const res = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 400);
  assert.strictEqual(data.success, false);
  assert.match(data.message, /special character/i);
});

test('LOGIN: Should block unverified password login and require phone verification', async () => {
  const payload = {
    identifier: 'arjun.test@example.com',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 403);
  assert.strictEqual(data.success, false);
  assert.strictEqual(data.isVerified, false);
  assert.match(data.message, /verify your mobile number/i);
});

test('OTP: Should reject fixed development bypass OTP values like 123456 or 000000', async () => {
  const verifyRes = await fetch(`${baseUrl}/auth/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543210', otp: '123456' }),
  });

  const verifyData = await verifyRes.json();
  assert.strictEqual(verifyRes.status, 400);
  assert.strictEqual(verifyData.success, false);
  assert.strictEqual(verifyData.message, 'Invalid OTP code');
});

test('OTP: Should send and verify valid 6-digit cryptographic OTP, transitioning isVerified to true and issuing JWT', async () => {
  const user = await User.findOne({ phone: '+919876543210' });
  assert.ok(user && user.otpInfo && user.otpInfo.code);
  const validOtp = user.otpInfo.code;
  assert.strictEqual(validOtp.length, 6);

  // Verify OTP
  const verifyRes = await fetch(`${baseUrl}/auth/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543210', otp: validOtp }),
  });

  const verifyData = await verifyRes.json();
  assert.strictEqual(verifyRes.status, 200);
  assert.strictEqual(verifyData.success, true);
  assert.ok(verifyData.accessToken);
  assert.strictEqual(verifyData.user.isVerified, true);

  // Verify DB state
  const updatedUser = await User.findOne({ phone: '+919876543210' });
  assert.strictEqual(updatedUser.isVerified, true);
  assert.strictEqual(updatedUser.otpInfo?.code, undefined); // Invalidate OTP code after success
});

test('OTP: Invalidate OTP after success so it cannot be reused', async () => {
  const verifyRes = await fetch(`${baseUrl}/auth/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543210', otp: '111111' }),
  });

  const verifyData = await verifyRes.json();
  assert.strictEqual(verifyRes.status, 400);
  assert.strictEqual(verifyData.success, false);
  assert.match(verifyData.message, /no active otp/i);
});

test('LOGIN: Should log in successfully with valid credentials after account is verified', async () => {
  const payload = {
    identifier: 'arjun.test@example.com',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.ok(data.accessToken);
  assert.strictEqual(data.user.email, 'arjun.test@example.com');
  assert.strictEqual(data.user.isVerified, true);
});

test('LOGIN: Should log in successfully with phone identifier', async () => {
  const payload = {
    identifier: '9876543210',
    password: 'StrongPassword123!',
  };

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(data.success, true);
  assert.ok(data.accessToken);
});

test('LOGIN: Should reject invalid password', async () => {
  const payload = {
    identifier: 'arjun.test@example.com',
    password: 'WrongPassword999!',
  };

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 401);
  assert.strictEqual(data.success, false);
});

test('LOGIN: Should reject non-existent user with generic message', async () => {
  const payload = {
    identifier: 'nobody@example.com',
    password: 'Password123!',
  };

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  assert.strictEqual(res.status, 401);
  assert.strictEqual(data.success, false);
  assert.strictEqual(data.message, 'Invalid credentials');
});

test('OTP: Should reject expired OTP', async () => {
  // Set expired OTP directly in user record
  const user = await User.findOne({ phone: '+919876543210' });
  user.otpInfo = {
    code: '888888',
    expiresAt: new Date(Date.now() - 60 * 1000), // 1 min ago
    attempts: 1,
    verificationAttempts: 0,
    lastRequestedAt: new Date(Date.now() - 120 * 1000),
  };
  await user.save();

  const verifyRes = await fetch(`${baseUrl}/auth/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543210', otp: '888888' }),
  });

  const verifyData = await verifyRes.json();
  assert.strictEqual(verifyRes.status, 400);
  assert.strictEqual(verifyData.success, false);
  assert.match(verifyData.message, /expired/i);
});

test('OTP: Should invalidate OTP after exceeding 5 failed verification attempts', async () => {
  // Set fresh OTP in user record
  const user = await User.findOne({ phone: '+919876543210' });
  user.otpInfo = {
    code: '777777',
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    attempts: 1,
    verificationAttempts: 5, // Already 5 failed attempts
    lastRequestedAt: new Date(Date.now() - 120 * 1000),
  };
  await user.save();

  // 6th attempt should fail and invalidate OTP
  const verifyRes = await fetch(`${baseUrl}/auth/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543210', otp: '777777' }),
  });

  const verifyData = await verifyRes.json();
  assert.strictEqual(verifyRes.status, 400);
  assert.strictEqual(verifyData.success, false);
  assert.match(verifyData.message, /too many failed verification attempts/i);

  const updated = await User.findOne({ phone: '+919876543210' });
  assert.strictEqual(updated.otpInfo?.code, undefined);
});

test('OTP: Should enforce cooldown rate limit on repeated OTP requests', async () => {
  const user = await User.findOne({ phone: '+919876543210' });
  user.otpInfo = {
    code: '654321',
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    attempts: 1,
    verificationAttempts: 0,
    lastRequestedAt: new Date(), // Just requested now (within 60s cooldown)
  };
  await user.save();

  const sendRes = await fetch(`${baseUrl}/auth/send-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543210' }),
  });

  const sendData = await sendRes.json();
  assert.strictEqual(sendRes.status, 429);
  assert.strictEqual(sendData.success, false);
  assert.match(sendData.message, /too many otp requests/i);
});

test('PROFILE & JWT: Should fetch profile with valid JWT bearer token', async () => {
  const loginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      identifier: 'arjun.test@example.com',
      password: 'StrongPassword123!',
    }),
  });

  const loginData = await loginRes.json();
  const token = loginData.accessToken;

  const profileRes = await fetch(`${baseUrl}/users/profile`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  const profileData = await profileRes.json();
  assert.strictEqual(profileRes.status, 200);
  assert.strictEqual(profileData.success, true);
  assert.strictEqual(profileData.data.email, 'arjun.test@example.com');
});

test('PROFILE & JWT: Should reject unauthenticated request missing token', async () => {
  const profileRes = await fetch(`${baseUrl}/users/profile`);
  const profileData = await profileRes.json();
  assert.strictEqual(profileRes.status, 401);
  assert.strictEqual(profileData.success, false);
});

test('PROFILE & JWT: Should reject invalid JWT token', async () => {
  const profileRes = await fetch(`${baseUrl}/users/profile`, {
    headers: { Authorization: 'Bearer fake_invalid_jwt_token_123' },
  });
  const profileData = await profileRes.json();
  assert.strictEqual(profileRes.status, 401);
  assert.strictEqual(profileData.success, false);
});

test('PROFILE & JWT: Should reject expired JWT token', async () => {
  const expiredToken = jwt.sign({ id: new mongoose.Types.ObjectId() }, getJwtSecret(), {
    expiresIn: '0s',
  });

  const profileRes = await fetch(`${baseUrl}/users/profile`, {
    headers: { Authorization: `Bearer ${expiredToken}` },
  });
  const profileData = await profileRes.json();
  assert.strictEqual(profileRes.status, 401);
  assert.strictEqual(profileData.success, false);
  assert.strictEqual(profileData.message, 'Invalid or expired token.');
});

test('JWT CONFIG: Should throw clear error if JWT_SECRET environment variable is missing', () => {
  const originalSecret = process.env.JWT_SECRET;
  try {
    delete process.env.JWT_SECRET;
    assert.throws(
      () => getJwtSecret(),
      /FATAL CONFIGURATION ERROR: JWT_SECRET environment variable is missing\./
    );
  } finally {
    process.env.JWT_SECRET = originalSecret;
  }
});

test('PASSWORD RESET: Should execute forgot password and reset password flow with strict policy', async () => {
  const forgotRes = await fetch(`${baseUrl}/auth/forgot-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'arjun.test@example.com' }),
  });

  const forgotData = await forgotRes.json();
  assert.strictEqual(forgotRes.status, 200);
  assert.strictEqual(forgotData.devResetToken, undefined); // No raw token in response

  // Retrieve hashed token from DB and simulate valid reset
  const user = await User.findOne({ email: 'arjun.test@example.com' });
  assert.ok(user.resetPasswordInfo && user.resetPasswordInfo.token);

  // Generate a test reset token pair to test reset-password endpoint
  const { rawToken, hashedToken, expiresAt } = passwordService.generateResetToken();
  user.resetPasswordInfo = { token: hashedToken, expiresAt };
  await user.save();

  // Attempt reset with weak password (missing special char)
  const weakResetRes = await fetch(`${baseUrl}/auth/reset-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token: rawToken,
      newPassword: 'BrandNewPassword123',
    }),
  });
  assert.strictEqual(weakResetRes.status, 400);

  // Reset password with strong password
  const resetRes = await fetch(`${baseUrl}/auth/reset-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token: rawToken,
      newPassword: 'BrandNewPassword123!',
    }),
  });

  const resetData = await resetRes.json();
  assert.strictEqual(resetRes.status, 200);
  assert.strictEqual(resetData.success, true);

  // Login with new password
  const newLoginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      identifier: 'arjun.test@example.com',
      password: 'BrandNewPassword123!',
    }),
  });

  const newLoginData = await newLoginRes.json();
  assert.strictEqual(newLoginRes.status, 200);
  assert.strictEqual(newLoginData.success, true);
});

test('Password Reset: Contract accepts password field name for client compatibility', async () => {
  const user = await User.findOne({ email: 'arjun.test@example.com' });
  const { rawToken, hashedToken, expiresAt } = passwordService.generateResetToken();
  user.resetPasswordInfo = { token: hashedToken, expiresAt };
  await user.save();

  const resetRes = await fetch(`${baseUrl}/auth/reset-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token: rawToken,
      password: 'AlternativePassword123!',
    }),
  });

  const resetData = await resetRes.json();
  assert.strictEqual(resetRes.status, 200);
  assert.strictEqual(resetData.success, true);

  // Verify login works with the reset password
  const loginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      identifier: 'arjun.test@example.com',
      password: 'AlternativePassword123!',
    }),
  });
  assert.strictEqual(loginRes.status, 200);
});
