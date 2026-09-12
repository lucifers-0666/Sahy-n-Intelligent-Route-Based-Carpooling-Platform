const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middleware/authMiddleware');
const {
  createRide,
  getRides,
  getMyRides,
  getRideById,
  updateRide,
  cancelRide,
  startBoarding,
  startTrip,
  completeTrip,
  calculateRoute,
  autocompletePlaces,
  searchRides,
} = require('../controllers/rideController');

// Route calculation & Places Autocomplete
router.post('/calculate-route', authenticate, calculateRoute);
router.get('/places/autocomplete', authenticate, autocompletePlaces);

// Search rides (Passenger search - Public / Optional Auth)
router.get('/search', optionalAuth, searchRides);

// General rides list with filters and pagination
router.get('/', optionalAuth, getRides);

// Driver's own rides (/my and /my-rides alias)
router.get('/my', authenticate, getMyRides);
router.get('/my-rides', authenticate, getMyRides);

// Create ride
router.post('/', authenticate, createRide);

// Single ride by ID
router.get('/:id', getRideById);

// Trip lifecycle management routes (Driver Only)
router.patch('/:id/start-boarding', authenticate, startBoarding);
router.patch('/:id/start', authenticate, startTrip);
router.patch('/:id/complete', authenticate, completeTrip);
router.patch('/:id/cancel', authenticate, cancelRide);

// Update / Delete ride
router.put('/:id', authenticate, updateRide);
router.patch('/:id', authenticate, updateRide);
router.delete('/:id', authenticate, cancelRide);

module.exports = router;

