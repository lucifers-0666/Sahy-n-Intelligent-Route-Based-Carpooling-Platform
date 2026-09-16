/**
 * Sahyān Real-Time Telematics Socket.IO Service
 *
 * Security & Protocol:
 *   - Fail-Closed JWT Handshake Authentication Middleware
 *   - Server-Side Ride & Driver Authorization against MongoDB Ride & Booking Models
 *   - Compact Payload Broadcasting (lat, lng, accuracy, speed, heading, timestamp)
 *   - Dynamic Room Management: "ride:<rideId>"
 */

const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../config/jwt');
const User = require('../models/User');
const Ride = require('../models/Ride');
const Booking = require('../models/Booking');
const LocationProcessor = require('./location/locationProcessor');

/**
 * @param {import('socket.io').Server} io
 */
function initSocketService(io) {
  /** @type {Map<string, { rideId: string, role: string, userId: string }>} */
  const socketMeta = new Map();

  // ── Fail-Closed JWT Handshake Authentication Middleware ─────────────────────
  io.use(async (socket, next) => {
    try {
      let token = socket.handshake.auth && socket.handshake.auth.token;
      if (!token && socket.handshake.headers && socket.handshake.headers.authorization) {
        const authHeader = socket.handshake.headers.authorization;
        if (authHeader.startsWith('Bearer ')) {
          token = authHeader.split(' ')[1];
        }
      }

      if (!token) {
        const err = new Error('AUTHENTICATION_REQUIRED');
        err.data = { code: 401, message: 'Authentication required. Valid access token missing in handshake.' };
        return next(err);
      }

      const secret = getJwtSecret();
      const decoded = jwt.verify(token, secret);
      const user = await User.findById(decoded.id).select('-password');

      if (!user) {
        const err = new Error('USER_NOT_FOUND');
        err.data = { code: 401, message: 'Invalid token: user account does not exist.' };
        return next(err);
      }

      socket.user = user;
      return next();
    } catch (err) {
      const authErr = new Error('INVALID_OR_EXPIRED_TOKEN');
      authErr.data = { code: 401, message: 'Invalid or expired access token.' };
      return next(authErr);
    }
  });

  io.on('connection', (socket) => {
    const authUserId = socket.user ? socket.user._id.toString() : 'unauthenticated';
    console.log(`[Socket.IO] Client connected: ${socket.id} (user: ${authUserId})`);

    // ── JOIN RIDE ROOM (Server-Side Authorization Enforced) ─────────────────
    socket.on('join_ride_room', async ({ rideId }) => {
      if (!rideId) {
        socket.emit('error', { message: 'join_ride_room requires rideId.' });
        return;
      }

      const userId = socket.user._id.toString();

      try {
        const ride = await Ride.findById(rideId).select('driver status');
        if (!ride) {
          socket.emit('error', { message: 'Ride not found.' });
          return;
        }

        const isDriver = ride.driver.toString() === userId;
        let isPassenger = false;

        if (!isDriver) {
          const booking = await Booking.findOne({
            ride: rideId,
            passenger: socket.user._id,
            status: { $in: ['pending', 'accepted', 'completed'] },
          }).select('_id');
          isPassenger = !!booking;
        }

        const isAdmin = socket.user.role === 'admin';

        if (!isDriver && !isPassenger && !isAdmin) {
          socket.emit('error', {
            message: 'Access denied: You are not an authorized participant in this ride.',
          });
          return;
        }

        const verifiedRole = isDriver ? 'driver' : 'passenger';
        const roomName = `ride:${rideId}`;
        socket.join(roomName);
        socketMeta.set(socket.id, { rideId, userId, role: verifiedRole });

        console.log(`[Socket.IO] ${verifiedRole}(${socket.id}, user: ${userId}) joined room ${roomName}`);

        // Acknowledge to the joining client
        socket.emit('room_joined', { rideId, roomName, role: verifiedRole });

        // Notify other room members that someone joined
        socket.to(roomName).emit('peer_joined', { userId, role: verifiedRole });
      } catch (err) {
        console.error(`[Socket.IO] Error verifying ride authorization for room join: ${err.message}`);
        socket.emit('error', { message: 'Internal authorization error while joining ride room.' });
      }
    });

    // ── DRIVER LOCATION UPDATE (Server-Side Verification Enforced) ─────────
    socket.on('driver_location_update', async (payload) => {
      const meta = socketMeta.get(socket.id);

      // Validate payload structure & values
      const valResult = LocationProcessor.validatePayload(payload);
      if (!valResult.valid) {
        socket.emit('error', { message: valResult.error || 'Invalid location payload.' });
        return;
      }

      const sanitized = valResult.sanitized;
      const { rideId } = sanitized;

      // Fail-closed role check
      if (!meta || meta.role !== 'driver') {
        socket.emit('error', { message: 'Unauthorized: Only the verified driver can emit location updates.' });
        return;
      }

      // Fail-closed database ownership verification
      try {
        const ride = await Ride.findById(rideId).select('driver status');
        if (!ride || ride.driver.toString() !== socket.user._id.toString()) {
          socket.emit('error', { message: 'Unauthorized: You are not the designated driver for this ride.' });
          return;
        }

        // Broadcast sanitized compact payload to all passengers in the room
        socket.to(`ride:${rideId}`).emit('passenger_location_stream', sanitized);
      } catch (dbErr) {
        console.error(`[Socket.IO] DB error verifying driver for location update: ${dbErr.message}`);
        socket.emit('error', { message: 'Database error during driver location verification.' });
      }
    });

    // ── LEAVE RIDE ROOM ─────────────────────────────────────────────────────
    socket.on('leave_ride_room', ({ rideId }) => {
      const roomName = `ride:${rideId}`;
      socket.leave(roomName);
      socketMeta.delete(socket.id);
      console.log(`[Socket.IO] ${socket.id} left room ${roomName}`);
      socket.to(roomName).emit('peer_left', { socketId: socket.id });
    });

    // ── TRIP STATUS BROADCAST ───────────────────────────────────────────────
    socket.on('broadcast_trip_status', async ({ rideId, status }) => {
      const meta = socketMeta.get(socket.id);
      if (!meta || meta.role !== 'driver') {
        socket.emit('error', { message: 'Unauthorized: Only the driver can broadcast trip status.' });
        return;
      }

      try {
        const ride = await Ride.findById(rideId).select('driver status');
        if (!ride || ride.driver.toString() !== socket.user._id.toString()) {
          socket.emit('error', { message: 'Unauthorized: You are not the driver of this ride.' });
          return;
        }

        io.to(`ride:${rideId}`).emit('trip_status_changed', { rideId, status });
      } catch (err) {
        socket.emit('error', { message: 'Database error during status broadcast.' });
      }
    });

    // ── DISCONNECT ──────────────────────────────────────────────────────────
    socket.on('disconnect', (reason) => {
      const meta = socketMeta.get(socket.id);
      if (meta) {
        const roomName = `ride:${meta.rideId}`;
        socket.to(roomName).emit('peer_left', {
          socketId: socket.id,
          role: meta.role,
          reason,
        });
        socketMeta.delete(socket.id);
      }
      console.log(`[Socket.IO] Client disconnected: ${socket.id} (${reason})`);
    });
  });

  console.log('[Socket.IO] Fail-closed telematics event handlers registered.');
}

module.exports = initSocketService;
