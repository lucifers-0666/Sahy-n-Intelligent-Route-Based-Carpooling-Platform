require('dotenv').config();
const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const vehicleRoutes = require('./routes/vehicleRoutes');
const rideRoutes = require('./routes/rideRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const messageRoutes = require('./routes/messageRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminRoutes = require('./routes/adminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const ticketRoutes = require('./routes/ticketRoutes');

const app = express();

// Global Middleware with Secure CORS & Webhook Raw-Body Preservation
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : [
      'http://localhost:5173',
      'http://localhost:3000',
      'http://127.0.0.1:5173',
      'http://10.0.2.2:5000',
    ];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps, curl, server-to-server) or matching allowed origins
      if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      if (process.env.NODE_ENV !== 'production') {
        return callback(null, true);
      }
      return callback(new Error(`CORS blocked for origin: ${origin}`));
    },
    credentials: true,
  })
);

app.use(
  express.json({
    verify: (req, res, buf) => {
      req.rawBody = buf;
    },
  })
);
app.use(express.urlencoded({ extended: true }));

// Health Check Endpoints
const healthHandler = (req, res) => {
  res.status(200).json({
    success: true,
    message: 'RouteShare API is running',
    status: 'OK',
    service: 'Sahyān Carpooling API Server',
    version: '1.0.0',
    data: {
      environment: process.env.NODE_ENV || 'development',
    },
    timestamp: new Date().toISOString(),
  });
};
app.get('/api/health', healthHandler);
app.get('/api/v1/health', healthHandler);

// Mount API routes for both /api and /api/v1 prefixes
['/api', '/api/v1'].forEach((prefix) => {
  app.use(`${prefix}/auth`, authRoutes);
  app.use(`${prefix}/users`, userRoutes);
  app.use(`${prefix}/vehicles`, vehicleRoutes);
  app.use(`${prefix}/rides`, rideRoutes);
  app.use(`${prefix}/bookings`, bookingRoutes);
  app.use(`${prefix}/messages`, messageRoutes);
  app.use(`${prefix}/reviews`, reviewRoutes);
  app.use(`${prefix}/notifications`, notificationRoutes);
  app.use(`${prefix}/payments`, paymentRoutes);
  app.use(`${prefix}/tickets`, ticketRoutes);
  app.use(`${prefix}/admin`, adminRoutes);
});

// Global 404 handler for undefined routes
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Endpoint not found: ${req.method} ${req.originalUrl}`,
  });
});

// Centralized Error Handling Middleware
app.use(errorHandler);

module.exports = app;
