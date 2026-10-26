const express = require('express');
const router = express.Router();
const { authenticate, adminAuth, requireRole } = require('../middleware/authMiddleware');
const { maskAdminPii } = require('../middleware/piiMasking');
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
  updatePlatformConfig,
  unmaskPii,
  forceRefundBooking,
  getDisputeCases,
  resolveDisputeCase,
  getFraudRiskSignals,
  getUserAppeals,
  reviewUserAppeal,
} = require('../controllers/adminController');

// All admin routes require authentication and admin role
router.use(authenticate, adminAuth);

// Core statistics
router.get('/stats', getAdminStats);

// User management (PII automatically masked by default)
router.get('/users', maskAdminPii, getUsers);
router.patch('/users/:id/verify', verifyDriver);
router.patch('/users/:id/suspend', requireRole(['super_admin', 'safety_officer']), suspendDriver);
router.patch('/users/:id/reactivate', requireRole(['super_admin', 'safety_officer']), reactivateDriver);

// Ride management
router.get('/rides', maskAdminPii, getRides);
router.patch('/rides/:id/moderate', moderateRide);

// Bookings (PII masked by default; force-refund protected by RBAC)
router.get('/bookings', maskAdminPii, getBookings);
router.post('/bookings/:id/force-refund', requireRole(['super_admin', 'safety_officer']), forceRefundBooking);

// Non-payment & Cash dispute cases (PII masked by default; outcome RBAC protected)
router.get('/disputes', maskAdminPii, getDisputeCases);
router.patch('/disputes/:id/resolve', requireRole(['super_admin', 'safety_officer', 'support_lead']), resolveDisputeCase);

// Fraud risk signals & elevated risk scores
router.get('/fraud/signals', getFraudRiskSignals);

// User appeals & Reinstatement
router.get('/appeals', maskAdminPii, getUserAppeals);
router.patch('/appeals/:userId/:appealIndex', requireRole(['super_admin', 'safety_officer']), reviewUserAppeal);

// Safety reports (PII masked by default)
router.get('/reports', maskAdminPii, getReports);
router.patch('/reports/:id/resolve', resolveReport);

// Audit logs & Unmasking PII
router.get('/audit-logs', getAuditLogs);
router.post('/audit/unmask-pii', unmaskPii);

// Revenue / monetization stats
router.get('/revenue-stats', getRevenueStats);

// Platform configuration
router.get('/config', getPlatformConfig);
router.patch('/config', requireRole(['super_admin', 'safety_officer']), updatePlatformConfig);

module.exports = router;
