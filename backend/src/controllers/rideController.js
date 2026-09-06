const mongoose = require('mongoose');
const Ride = require('../models/Ride');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const googleMapsService = require('../services/googleMapsService');

/**
 * Validate geographic coordinate pair
 */
function isValidCoordinate(lat, lng) {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    !isNaN(lat) &&
    !isNaN(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

/**
 * @desc    Create / Offer a new ride
 * @route   POST /api/v1/rides
 * @access  Private (Authenticated Driver)
 */
const createRide = async (req, res, next) => {
  try {
    const {
      vehicleId,
      origin,
      destination,
      route,
      departureTime,
      estimatedArrivalTime,
      availableSeats,
      contributionPerSeat,
      pickupPolicy,
      amenities,
      notes,
    } = req.body;

    // 1. Field presence validation
    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: 'Vehicle ID is required.',
      });
    }

    if (!origin || typeof origin !== 'object' || !origin.name) {
      return res.status(400).json({
        success: false,
        message: 'Valid origin with name and coordinates is required.',
      });
    }

    if (!destination || typeof destination !== 'object' || !destination.name) {
      return res.status(400).json({
        success: false,
        message: 'Valid destination with name and coordinates is required.',
      });
    }

    // 2. Coordinate validation
    const originLat = Number(origin.latitude);
    const originLng = Number(origin.longitude);
    const destLat = Number(destination.latitude);
    const destLng = Number(destination.longitude);

    if (!isValidCoordinate(originLat, originLng)) {
      return res.status(400).json({
        success: false,
        message: 'Origin coordinates must be valid latitude (-90 to 90) and longitude (-180 to 180).',
      });
    }

    if (!isValidCoordinate(destLat, destLng)) {
      return res.status(400).json({
        success: false,
        message: 'Destination coordinates must be valid latitude (-90 to 90) and longitude (-180 to 180).',
      });
    }

    // 3. Ensure origin and destination are distinct
    const distSq = Math.pow(originLat - destLat, 2) + Math.pow(originLng - destLng, 2);
    if (distSq < 0.000001) {
      return res.status(400).json({
        success: false,
        message: 'Origin and destination locations must not be identical.',
      });
    }

    // 4. Route information validation
    if (!route || typeof route !== 'object' || !route.encodedPolyline) {
      return res.status(400).json({
        success: false,
        message: 'Valid route information with encoded polyline, distance, and duration is required.',
      });
    }

    const distanceMeters = Number(route.distanceMeters);
    const durationSeconds = Number(route.durationSeconds);
    if (isNaN(distanceMeters) || distanceMeters <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Route distance in meters must be a positive number.',
      });
    }
    if (isNaN(durationSeconds) || durationSeconds <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Route duration in seconds must be a positive number.',
      });
    }

    // 5. Date & Time validation
    const depTime = new Date(departureTime);
    if (isNaN(depTime.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Departure time must be a valid date.',
      });
    }

    // Ensure departure time is not significantly in the past (allow 5-minute clock drift)
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (depTime < fiveMinutesAgo) {
      return res.status(400).json({
        success: false,
        message: 'Departure time cannot be in the past.',
      });
    }

    let arrTime;
    if (estimatedArrivalTime) {
      arrTime = new Date(estimatedArrivalTime);
      if (isNaN(arrTime.getTime()) || arrTime <= depTime) {
        return res.status(400).json({
          success: false,
          message: 'Estimated arrival time must be after departure time.',
        });
      }
    } else {
      // Auto-compute from route duration if not explicitly supplied
      arrTime = new Date(depTime.getTime() + durationSeconds * 1000);
    }

    // 6. Vehicle existence and ownership authorization
    if (!mongoose.Types.ObjectId.isValid(vehicleId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle ID format.',
      });
    }

    const vehicle = await Vehicle.findById(vehicleId);
    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found.',
      });
    }

    if (vehicle.owner.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You do not own this vehicle.',
      });
    }

    if (vehicle.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Selected vehicle is not active for rides.',
      });
    }

    // 7. Seats and contribution validation
    const parsedAvailableSeats = Number(availableSeats);
    if (!Number.isInteger(parsedAvailableSeats) || parsedAvailableSeats < 1) {
      return res.status(400).json({
        success: false,
        message: 'Available seats must be a positive integer of at least 1.',
      });
    }

    if (parsedAvailableSeats > vehicle.seatCapacity) {
      return res.status(400).json({
        success: false,
        message: `Available seats (${parsedAvailableSeats}) cannot exceed vehicle capacity (${vehicle.seatCapacity}).`,
      });
    }

    const parsedContribution = Number(contributionPerSeat);
    if (isNaN(parsedContribution) || parsedContribution < 0) {
      return res.status(400).json({
        success: false,
        message: 'Contribution per seat must be a non-negative number.',
      });
    }

    // 8. Prepare GeoJSON representations
    const originLocation = {
      name: String(origin.name).trim(),
      latitude: originLat,
      longitude: originLng,
      placeId: origin.placeId || null,
      point: {
        type: 'Point',
        coordinates: [originLng, originLat],
      },
    };

    const destLocation = {
      name: String(destination.name).trim(),
      latitude: destLat,
      longitude: destLng,
      placeId: destination.placeId || null,
      point: {
        type: 'Point',
        coordinates: [destLng, destLat],
      },
    };

    const routeData = {
      encodedPolyline: String(route.encodedPolyline).trim(),
      distanceMeters,
      durationSeconds,
    };

    // 9. Construct and save the ride
    const ride = new Ride({
      driver: req.user._id,
      vehicle: vehicle._id,
      origin: originLocation,
      destination: destLocation,
      route: routeData,
      departureTime: depTime,
      estimatedArrivalTime: arrTime,
      availableSeats: parsedAvailableSeats,
      totalSeats: vehicle.seatCapacity,
      bookedSeats: 0,
      contributionPerSeat: parsedContribution,
      pickupPolicy: pickupPolicy === 'exact' ? 'exact' : 'nearby',
      amenities: Array.isArray(amenities) ? amenities : [],
      notes: notes ? String(notes).trim() : '',
      status: 'scheduled',
    });

    await ride.save();

    // Populate driver and vehicle details before responding
    await ride.populate([
      { path: 'vehicle' },
      { path: 'driver', select: 'name email phone profileImage city rating isVerified isPhoneVerified isIdentityVerified' },
    ]);

    return res.status(201).json({
      success: true,
      message: 'Ride offered successfully.',
      ride,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get all rides created by the authenticated driver
 * @route   GET /api/v1/rides/my
 * @access  Private (Authenticated Driver)
 */
const getMyRides = async (req, res, next) => {
  try {
    const filter = { driver: req.user._id };

    if (req.query.status) {
      filter.status = req.query.status;
    }

    const rides = await Ride.find(filter)
      .populate('vehicle')
      .populate('driver', 'name email phone profileImage city rating isVerified isPhoneVerified isIdentityVerified')
      .sort({ departureTime: -1 });

    return res.status(200).json({
      success: true,
      count: rides.length,
      rides,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get single ride by ID
 * @route   GET /api/v1/rides/:id
 * @access  Public / Authenticated
 */
const getRideById = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ride ID format.',
      });
    }

    const ride = await Ride.findById(id)
      .populate('vehicle')
      .populate('driver', 'name email phone profileImage city rating isVerified isPhoneVerified isIdentityVerified');

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found.',
      });
    }

    return res.status(200).json({
      success: true,
      ride,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update a scheduled ride
 * @route   PUT /api/v1/rides/:id
 * @access  Private (Driver Only)
 */
const updateRide = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ride ID format.',
      });
    }

    const ride = await Ride.findById(id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found.',
      });
    }

    // Enforce ownership
    if (ride.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only modify your own rides.',
      });
    }

    // Only scheduled rides can be modified
    if (ride.status !== 'scheduled') {
      return res.status(400).json({
        success: false,
        message: `Cannot update a ride in '${ride.status}' status.`,
      });
    }

    const {
      availableSeats,
      contributionPerSeat,
      departureTime,
      pickupPolicy,
      amenities,
      notes,
    } = req.body;

    if (availableSeats !== undefined) {
      const parsed = Number(availableSeats);
      if (!Number.isInteger(parsed) || parsed < 1 || parsed > ride.totalSeats) {
        return res.status(400).json({
          success: false,
          message: `Available seats must be between 1 and ${ride.totalSeats}.`,
        });
      }
      if (parsed < ride.bookedSeats) {
        return res.status(400).json({
          success: false,
          message: `Available seats cannot be less than already booked seats (${ride.bookedSeats}).`,
        });
      }
      ride.availableSeats = parsed;
    }

    if (contributionPerSeat !== undefined) {
      const parsedContrib = Number(contributionPerSeat);
      if (isNaN(parsedContrib) || parsedContrib < 0) {
        return res.status(400).json({
          success: false,
          message: 'Contribution per seat must be a non-negative number.',
        });
      }
      ride.contributionPerSeat = parsedContrib;
    }

    if (departureTime !== undefined) {
      const newDepTime = new Date(departureTime);
      if (isNaN(newDepTime.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Departure time must be a valid date.',
        });
      }
      ride.departureTime = newDepTime;
    }

    if (pickupPolicy !== undefined) {
      if (!['exact', 'nearby'].includes(pickupPolicy)) {
        return res.status(400).json({
          success: false,
          message: 'Pickup policy must be exact or nearby.',
        });
      }
      ride.pickupPolicy = pickupPolicy;
    }

    if (amenities !== undefined) {
      ride.amenities = Array.isArray(amenities) ? amenities : [];
    }

    if (notes !== undefined) {
      ride.notes = String(notes).trim();
    }

    await ride.save();
    await ride.populate([
      { path: 'vehicle' },
      { path: 'driver', select: 'name email phone profileImage city rating isVerified isPhoneVerified isIdentityVerified' },
    ]);

    return res.status(200).json({
      success: true,
      message: 'Ride updated successfully.',
      ride,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Cancel a ride
 * @route   PATCH /api/v1/rides/:id/cancel
 * @access  Private (Driver Only)
 */
const cancelRide = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ride ID format.',
      });
    }

    const ride = await Ride.findById(id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found.',
      });
    }

    // Enforce ownership
    if (ride.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only cancel your own rides.',
      });
    }

    if (ride.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Ride is already cancelled.',
      });
    }

    if (ride.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a completed ride.',
      });
    }

    ride.status = 'cancelled';
    await ride.save();
    await ride.populate([
      { path: 'vehicle' },
      { path: 'driver', select: 'name email phone profileImage city rating isVerified isPhoneVerified isIdentityVerified' },
    ]);

    return res.status(200).json({
      success: true,
      message: 'Ride cancelled successfully.',
      ride,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Calculate route between origin and destination via Google Maps Platform
 * @route   POST /api/v1/rides/calculate-route
 * @access  Private
 */
const calculateRoute = async (req, res, next) => {
  try {
    const { origin, destination } = req.body;

    if (!origin || !destination) {
      return res.status(400).json({
        success: false,
        message: 'Both origin and destination with latitude and longitude are required.',
      });
    }

    const originLat = Number(origin.latitude);
    const originLng = Number(origin.longitude);
    const destLat = Number(destination.latitude);
    const destLng = Number(destination.longitude);

    if (!isValidCoordinate(originLat, originLng) || !isValidCoordinate(destLat, destLng)) {
      return res.status(400).json({
        success: false,
        message: 'Valid coordinates are required for route calculation.',
      });
    }

    const result = await googleMapsService.calculateRoute(
      { latitude: originLat, longitude: originLng, name: origin.name || '' },
      { latitude: destLat, longitude: destLng, name: destination.name || '' }
    );

    if (!result.success) {
      return res.status(result.error === 'GOOGLE_MAPS_KEY_NOT_CONFIGURED' ? 503 : 400).json(result);
    }

    return res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Autocomplete places search
 * @route   GET /api/v1/rides/places/autocomplete
 * @access  Private
 */
const autocompletePlaces = async (req, res, next) => {
  try {
    const { input } = req.query;

    if (!input || String(input).trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Search query must be at least 2 characters.',
        predictions: [],
      });
    }

    const result = await googleMapsService.autocompletePlaces(String(input).trim());

    if (!result.success && result.error === 'GOOGLE_MAPS_KEY_NOT_CONFIGURED') {
      return res.status(503).json(result);
    }

    return res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createRide,
  getMyRides,
  getRideById,
  updateRide,
  cancelRide,
  calculateRoute,
  autocompletePlaces,
};
