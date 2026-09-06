const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createRide,
  getMyRides,
  getRideById,
  updateRide,
  cancelRide,
  calculateRoute,
  autocompletePlaces,
} = require('../controllers/rideController');

// Route calculation & Places Autocomplete
router.post('/calculate-route', authenticate, calculateRoute);
router.get('/places/autocomplete', authenticate, autocompletePlaces);

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
