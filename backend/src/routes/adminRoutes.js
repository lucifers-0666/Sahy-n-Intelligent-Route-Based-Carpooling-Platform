const express = require('express');
const router = express.Router();
const { authenticate, adminAuth } = require('../middleware/authMiddleware');
const {
  getAdminStats,
  getUsers,
  verifyDriver,
  getRides,
  moderateRide,
  getReports,
  resolveReport,
  getBookings,
  suspendDriver,
  reactivateDriver,
  getAuditLogs,
  getRevenueStats,
  getPlatformConfig,
} = require('../controllers/adminController');

// All admin routes require authentication and admin role
router.use(authenticate, adminAuth);

// Core statistics
router.get('/stats', getAdminStats);

// User management
router.get('/users', getUsers);
router.patch('/users/:id/verify', verifyDriver);
router.patch('/users/:id/suspend', suspendDriver);
router.patch('/users/:id/reactivate', reactivateDriver);

// Ride management
router.get('/rides', getRides);
router.patch('/rides/:id/moderate', moderateRide);

// Bookings
router.get('/bookings', getBookings);

// Safety reports
router.get('/reports', getReports);
router.patch('/reports/:id/resolve', resolveReport);

// Audit logs
router.get('/audit-logs', getAuditLogs);

// Revenue / monetization stats
router.get('/revenue-stats', getRevenueStats);

// Platform configuration
router.get('/config', getPlatformConfig);

module.exports = router;
