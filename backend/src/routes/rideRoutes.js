const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middleware/authMiddleware');
const {
  createRide,
  getMyRides,
  getRideById,
  updateRide,
  cancelRide,
  calculateRoute,
  autocompletePlaces,
  searchRides,
} = require('../controllers/rideController');

// Route calculation & Places Autocomplete
router.post('/calculate-route', authenticate, calculateRoute);
router.get('/places/autocomplete', authenticate, autocompletePlaces);

// Search rides (Passenger search - Public / Optional Auth)
router.get('/search', optionalAuth, searchRides);

// Driver's own rides
router.get('/my', authenticate, getMyRides);

// Create ride
router.post('/', authenticate, createRide);

// Single ride by ID
router.get('/:id', getRideById);


// Update / Cancel ride
router.put('/:id', authenticate, updateRide);
router.patch('/:id/cancel', authenticate, cancelRide);
router.delete('/:id', authenticate, cancelRide);

module.exports = router;
