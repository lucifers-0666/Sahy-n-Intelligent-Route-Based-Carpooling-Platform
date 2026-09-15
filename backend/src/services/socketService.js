/**
 * Sahyān Real-Time Telematics Socket.IO Service
 *
 * Room & event protocol:
 *   join_ride_room            { rideId, userId, role }           → joins room "ride:<rideId>"
 *   driver_location_update    { rideId, lat, lng, heading, speed, timestamp }
 *                              → validates sender is driver, broadcasts passenger_location_stream
 *   leave_ride_room           { rideId }                         → cleans up subscription
 *   trip_status_changed       (server→room)  { rideId, status }
 *
 * Internal state: socketMeta Map tracks each socket's active rideId and role
 * so only the designated driver can emit location updates for a given room.
 */

/**
 * @param {import('socket.io').Server} io
 */
function initSocketService(io) {
  /** @type {Map<string, { rideId: string, role: string, userId: string }>} */
  const socketMeta = new Map();

  io.on('connection', (socket) => {
    console.log(`[Socket.IO] Client connected: ${socket.id}`);

    // ── JOIN RIDE ROOM ──────────────────────────────────────────────────────
    socket.on('join_ride_room', ({ rideId, userId, role }) => {
      if (!rideId || !role) {
        socket.emit('error', { message: 'join_ride_room requires rideId and role.' });
        return;
      }

      const roomName = `ride:${rideId}`;
      socket.join(roomName);
      socketMeta.set(socket.id, { rideId, userId: userId || 'anonymous', role });

      console.log(`[Socket.IO] ${role}(${socket.id}) joined room ${roomName}`);

      // Acknowledge to the joining client
      socket.emit('room_joined', { rideId, roomName, role });

      // Notify other room members that someone joined
      socket.to(roomName).emit('peer_joined', { userId, role });
    });

    // ── DRIVER LOCATION UPDATE ──────────────────────────────────────────────
    socket.on('driver_location_update', (payload) => {
      const meta = socketMeta.get(socket.id);

      // Security: only the driver of this ride may emit location updates
      if (!meta || meta.role !== 'driver') {
        socket.emit('error', { message: 'Only the driver can emit location updates.' });
        return;
      }

      const { rideId, latitude, longitude, heading, speed, timestamp } = payload;

      if (!rideId || latitude == null || longitude == null) {
        socket.emit('error', { message: 'driver_location_update missing required fields.' });
        return;
      }

      const enriched = {
        rideId,
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        heading: parseFloat(heading ?? 0),
        speed: parseFloat(speed ?? 0),
        timestamp: timestamp || new Date().toISOString(),
      };

      // Broadcast to all *other* sockets in the room (passengers)
      socket.to(`ride:${rideId}`).emit('passenger_location_stream', enriched);
    });

    // ── LEAVE RIDE ROOM ─────────────────────────────────────────────────────
    socket.on('leave_ride_room', ({ rideId }) => {
      const roomName = `ride:${rideId}`;
      socket.leave(roomName);
      socketMeta.delete(socket.id);
      console.log(`[Socket.IO] ${socket.id} left room ${roomName}`);
      socket.to(roomName).emit('peer_left', { socketId: socket.id });
    });

    // ── TRIP STATUS BROADCAST (called by REST controllers via io ref) ───────
    socket.on('broadcast_trip_status', ({ rideId, status }) => {
      const meta = socketMeta.get(socket.id);
      if (!meta || meta.role !== 'driver') return;
      io.to(`ride:${rideId}`).emit('trip_status_changed', { rideId, status });
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

  console.log('[Socket.IO] Telematics event handlers registered.');
}

module.exports = initSocketService;
