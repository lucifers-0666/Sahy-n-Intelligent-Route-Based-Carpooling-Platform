const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { Server } = require('socket.io');
const ioClient = require('socket.io-client');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

process.env.JWT_SECRET = 'test_jwt_secret_key_1234567890_socket';

const { MongoMemoryServer, MongoMemoryReplSet } = require('mongodb-memory-server');

const initSocketService = require('../src/services/socketService');
const { getJwtSecret } = require('../src/config/jwt');
const User = require('../src/models/User');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');

let mongoServer;
let server;
let io;
let serverPort;
let driverUser;
let passengerUser;
let unauthorizedUser;
let testRide;
let testBooking;

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
      const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_socket_test';
      await mongoose.connect(mongoUri);
    }
  }

  await User.init();
  await Ride.init();
  await Booking.init();

  // Create test HTTP & Socket.IO server
  server = http.createServer();
  io = new Server(server, {
    cors: { origin: '*' },
    transports: ['websocket'],
  });
  initSocketService(io);

  await new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      serverPort = server.address().port;
      resolve();
    });
  });

  // Seed test users
  const timestamp = Date.now();
  driverUser = await User.create({
    name: 'Socket Driver',
    email: `driver_${timestamp}@test.com`,
    phone: `+9198765${Math.floor(10000 + Math.random() * 90000)}`,
    password: 'Password123!',
    role: 'user',
    isDriver: true,
  });

  passengerUser = await User.create({
    name: 'Socket Passenger',
    email: `passenger_${timestamp}@test.com`,
    phone: `+9198765${Math.floor(10000 + Math.random() * 90000)}`,
    password: 'Password123!',
    role: 'user',
  });

  unauthorizedUser = await User.create({
    name: 'Socket Stranger',
    email: `stranger_${timestamp}@test.com`,
    phone: `+9198765${Math.floor(10000 + Math.random() * 90000)}`,
    password: 'Password123!',
    role: 'user',
  });

  const Vehicle = require('../src/models/Vehicle');
  const vehicle = await Vehicle.create({
    owner: driverUser._id,
    make: 'Hyundai',
    model: 'Creta',
    registrationNumber: `GJ01SK${Math.floor(1000 + Math.random() * 9000)}`,
    vehicleType: 'sedan',
    seatCapacity: 4,
    color: 'White',
    year: 2022,
  });

  testRide = await Ride.create({
    driver: driverUser._id,
    vehicle: vehicle._id,
    origin: {
      name: 'Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    destination: {
      name: 'Rajkot',
      latitude: 22.3039,
      longitude: 70.8022,
      point: { type: 'Point', coordinates: [70.8022, 22.3039] },
    },
    route: {
      encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq',
      distanceMeters: 219000,
      durationSeconds: 12000,
    },
    departureTime: new Date(Date.now() + 3600000),
    estimatedArrivalTime: new Date(Date.now() + 15600000),
    availableSeats: 3,
    totalSeats: 3,
    contributionPerSeat: 450,
    status: 'active',
  });

  testBooking = await Booking.create({
    passenger: passengerUser._id,
    ride: testRide._id,
    requestedSeats: 1,
    contributionPerSeat: 450,
    totalContribution: 450,
    status: 'accepted',
    pickup: {
      name: 'Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
      point: { type: 'Point', coordinates: [72.5714, 23.0225] },
    },
    drop: {
      name: 'Rajkot',
      latitude: 22.3039,
      longitude: 70.8022,
      point: { type: 'Point', coordinates: [70.8022, 22.3039] },
    },
  });
});

test.after(async () => {
  if (io) io.close();
  if (server) server.close();
});

test('SOCKET SECURITY: Rejects unauthenticated handshake without JWT token', async () => {
  const socketUrl = `http://127.0.0.1:${serverPort}`;
  const client = ioClient(socketUrl, {
    transports: ['websocket'],
    reconnection: false,
  });

  const err = await new Promise((resolve) => {
    client.on('connect_error', (error) => {
      resolve(error.message);
    });
    client.on('connect', () => {
      resolve(null);
    });
  });

  client.disconnect();
  assert.equal(err, 'AUTHENTICATION_REQUIRED');
});

test('SOCKET SECURITY: Rejects handshake with invalid/corrupted JWT token', async () => {
  const socketUrl = `http://127.0.0.1:${serverPort}`;
  const client = ioClient(socketUrl, {
    auth: { token: 'invalid.jwt.token' },
    transports: ['websocket'],
    reconnection: false,
  });

  const err = await new Promise((resolve) => {
    client.on('connect_error', (error) => {
      resolve(error.message);
    });
  });

  client.disconnect();
  assert.equal(err, 'INVALID_OR_EXPIRED_TOKEN');
});

test('SOCKET SECURITY: Connects successfully with valid JWT and joins room as verified driver', async () => {
  const secret = getJwtSecret();
  const driverToken = jwt.sign({ id: driverUser._id }, secret, { expiresIn: '1h' });

  const socketUrl = `http://127.0.0.1:${serverPort}`;
  const client = ioClient(socketUrl, {
    auth: { token: driverToken },
    transports: ['websocket'],
    reconnection: false,
  });

  await new Promise((resolve) => {
    client.on('connect', resolve);
  });

  client.emit('join_ride_room', { rideId: testRide._id.toString() });

  const roomJoined = await new Promise((resolve) => {
    client.on('room_joined', resolve);
  });

  assert.equal(roomJoined.rideId, testRide._id.toString());
  assert.equal(roomJoined.role, 'driver');

  client.disconnect();
});

test('SOCKET SECURITY: Rejects unauthorized third-party user from joining ride room', async () => {
  const secret = getJwtSecret();
  const strangerToken = jwt.sign({ id: unauthorizedUser._id }, secret, { expiresIn: '1h' });

  const socketUrl = `http://127.0.0.1:${serverPort}`;
  const client = ioClient(socketUrl, {
    auth: { token: strangerToken },
    transports: ['websocket'],
    reconnection: false,
  });

  await new Promise((resolve) => {
    client.on('connect', resolve);
  });

  client.emit('join_ride_room', { rideId: testRide._id.toString() });

  const err = await new Promise((resolve) => {
    client.on('error', resolve);
  });

  assert.match(err.message, /Access denied/);
  client.disconnect();
});

test('SOCKET SECURITY: Driver emits location update and booked passenger receives broadcast', async () => {
  const secret = getJwtSecret();
  const driverToken = jwt.sign({ id: driverUser._id }, secret, { expiresIn: '1h' });
  const passengerToken = jwt.sign({ id: passengerUser._id }, secret, { expiresIn: '1h' });

  const socketUrl = `http://127.0.0.1:${serverPort}`;
  const driverClient = ioClient(socketUrl, {
    auth: { token: driverToken },
    transports: ['websocket'],
  });
  const passengerClient = ioClient(socketUrl, {
    auth: { token: passengerToken },
    transports: ['websocket'],
  });

  await Promise.all([
    new Promise((resolve) => driverClient.on('connect', resolve)),
    new Promise((resolve) => passengerClient.on('connect', resolve)),
  ]);

  driverClient.emit('join_ride_room', { rideId: testRide._id.toString() });
  passengerClient.emit('join_ride_room', { rideId: testRide._id.toString() });

  await new Promise((r) => setTimeout(r, 100));

  const payload = {
    rideId: testRide._id.toString(),
    latitude: 23.0250,
    longitude: 72.5720,
    accuracy: 8.5,
    speed: 55.0,
    heading: 90.0,
    timestamp: new Date().toISOString(),
  };

  const receivePromise = new Promise((resolve) => {
    passengerClient.on('passenger_location_stream', (data) => {
      resolve(data);
    });
  });

  driverClient.emit('driver_location_update', payload);

  const received = await receivePromise;
  assert.equal(received.rideId, testRide._id.toString());
  assert.equal(received.latitude, 23.0250);
  assert.equal(received.speed, 55.0);

  driverClient.disconnect();
  passengerClient.disconnect();
});

test.after(async () => {
  if (io) {
    io.close();
  }
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});
