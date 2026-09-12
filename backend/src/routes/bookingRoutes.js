const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createBooking,
  getMyBookings,
  getBookingById,
  cancelBooking,
  getDriverBookingRequests,
  acceptBooking,
  rejectBooking,
  updateBookingStatus,
} = require('../controllers/bookingController');

// All booking endpoints require authentication
router.use(authenticate);

// Create new booking request
router.post('/', createBooking);

// Get passenger's own bookings (/my and /my-bookings alias)
router.get('/my', getMyBookings);
router.get('/my-bookings', getMyBookings);

// Get driver's incoming booking requests for offered rides
router.get('/driver/requests', getDriverBookingRequests);

// Get single booking by ID
router.get('/:id', getBookingById);

// Status update (Driver: accept/confirm or reject)
router.patch('/:id/status', updateBookingStatus);

// Cancel booking request (Passenger / Driver)
router.patch('/:id/cancel', cancelBooking);

// Accept pending booking request (Driver)
router.patch('/:id/accept', acceptBooking);

// Reject pending booking request (Driver)
router.patch('/:id/reject', rejectBooking);

module.exports = router;
