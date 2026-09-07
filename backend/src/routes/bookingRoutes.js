const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createBooking,
  getMyBookings,
  getBookingById,
  cancelBooking,
} = require('../controllers/bookingController');

// All booking endpoints require authentication
router.use(authenticate);

// Create new booking request
router.post('/', createBooking);

// Get passenger's own bookings
router.get('/my', getMyBookings);

// Get single booking by ID
router.get('/:id', getBookingById);

// Cancel pending booking request
router.patch('/:id/cancel', cancelBooking);

module.exports = router;
