require('dotenv').config();
const http = require('http');
const app = require('./app');
const connectDB = require('./config/db');
const { Server } = require('socket.io');
const initSocketService = require('./services/socketService');

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';

// Initialize Database connection
connectDB();

// Wrap Express app with native HTTP server so Socket.IO can share the port
const httpServer = http.createServer(app);

// Initialize Socket.IO with permissive CORS for local development
const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  transports: ['websocket', 'polling'],
});

// Boot real-time telematics event handlers
initSocketService(io);

httpServer.listen(PORT, HOST, () => {
  console.log(`[SERVER]    Sahyān Backend Server running on http://${HOST}:${PORT}`);
  console.log(`[HEALTH]    Health Check:  http://localhost:${PORT}/api/health`);
  console.log(`[Socket.IO] Real-time engine listening on port ${PORT}`);
});
