require('dotenv').config();
const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const vehicleRoutes = require('./routes/vehicleRoutes');
const rideRoutes = require('./routes/rideRoutes');
const bookingRoutes = require('./routes/bookingRoutes');

const app = express();

// Global Middleware
app.use(cors());
app.use(express.json());
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
