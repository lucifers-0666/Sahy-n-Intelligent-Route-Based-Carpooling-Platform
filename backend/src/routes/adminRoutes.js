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
} = require('../controllers/adminController');

// All admin routes require authentication and admin role
router.use(authenticate, adminAuth);

router.get('/stats', getAdminStats);
router.get('/users', getUsers);
router.patch('/users/:id/verify', verifyDriver);
router.get('/rides', getRides);
router.patch('/rides/:id/moderate', moderateRide);
router.get('/bookings', getBookings);
router.get('/reports', getReports);
router.patch('/reports/:id/resolve', resolveReport);

module.exports = router;
