const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const Ride = require('../models/Ride');

/**
 * Sahyan Capacity Model Definition (Phase 8 & Future Phase 9):
 * 
 * totalSeats: Physical passenger capacity available for the ride.
 * bookedSeats: Seats belonging to ACCEPTED bookings (consumed capacity).
 * availableSeats: Immediately requestable capacity (not reserved by pending requests,
 *                 and not consumed by accepted bookings).
 * 
 * Phase 8 Lifecycle:
 * - When pending booking is created: availableSeats decreases by requestedSeats.
 * - When pending booking is cancelled: availableSeats increases by requestedSeats.
 * 
 * Future Phase 9 Contract:
 * - When driver ACCEPTS pending booking: DO NOT decrement availableSeats again!
 *   Instead: bookedSeats increases by requestedSeats (seats were already reserved).
 * - When driver REJECTS pending booking: availableSeats increases by requestedSeats.
 */

/**
 * Helper to validate geographic coordinates without truthiness bugs
 * Validates that latitude is between -90 and 90, longitude between -180 and 180.
 */
function isValidCoordinate(lat, lng) {
  return (
    typeof lat === 'number' &&
    Number.isFinite(lat) &&
    lat >= -90 &&
    lat <= 90 &&
    typeof lng === 'number' &&
    Number.isFinite(lng) &&
    lng >= -180 &&
    lng <= 180
  );
}

/**
 * @desc    Create a new booking request for a scheduled ride
 * @route   POST /api/v1/bookings
 * @access  Private (Passenger)
 */
exports.createBooking = async (req, res, next) => {
  try {
    const passengerId = req.user.id;
    const { rideId, requestedSeats, passengerNote, pickup, drop } = req.body;

    // 1. Validate required fields
    if (!rideId) {
      return res.status(400).json({
        success: false,
        message: 'Ride ID is required',
      });
    }

    if (!mongoose.Types.ObjectId.isValid(rideId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ride ID format',
      });
    }

    const seats = Number(requestedSeats);
    if (!Number.isInteger(seats) || seats < 1 || seats > 8) {
      return res.status(400).json({
        success: false,
        message: 'Requested seats must be an integer between 1 and 8',
      });
    }

    // Validate passenger note if provided
    if (passengerNote !== undefined && passengerNote !== null) {
      if (typeof passengerNote !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Passenger note must be a string',
        });
      }
      if (passengerNote.length > 500) {
        return res.status(400).json({
          success: false,
          message: 'Passenger note cannot exceed 500 characters',
        });
      }
    }

    // 2. Fetch ride and verify availability
    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found',
      });
    }

    if (ride.status !== 'scheduled') {
      return res.status(409).json({
        success: false,
        message: `Ride is not accepting bookings (status: ${ride.status})`,
      });
    }

    if (new Date(ride.departureTime) <= new Date()) {
      return res.status(409).json({
        success: false,
        message: 'Ride has already departed',
      });
    }

    // 3. Prevent driver from booking their own ride
    if (ride.driver.toString() === passengerId.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Drivers cannot book seats on their own rides',
      });
    }

    // 4. In-memory check for existing active booking requests
    const existingActiveBooking = await Booking.findOne({
      passenger: passengerId,
      ride: rideId,
      status: { $in: ['pending', 'accepted'] },
    });

    if (existingActiveBooking) {
      return res.status(409).json({
        success: false,
        message: 'You already have an active booking request for this ride',
      });
    }

    // 5. Validate pickup & drop coordinates if supplied
    let pickupSnapshot;
    if (pickup !== undefined && pickup !== null) {
      if (
        typeof pickup !== 'object' ||
        typeof pickup.name !== 'string' ||
        !pickup.name.trim() ||
        !isValidCoordinate(pickup.latitude, pickup.longitude)
      ) {
        return res.status(400).json({
          success: false,
          message:
            'Invalid pickup location: name must be a non-empty string and coordinates must be valid (latitude -90..90, longitude -180..180)',
        });
      }
      pickupSnapshot = {
        name: pickup.name.trim(),
        latitude: pickup.latitude,
        longitude: pickup.longitude,
        point: {
          type: 'Point',
          coordinates: [pickup.longitude, pickup.latitude],
        },
      };
    } else {
      pickupSnapshot = {
        name: ride.origin.name,
        latitude: ride.origin.latitude,
        longitude: ride.origin.longitude,
        point: ride.origin.point,
      };
    }

    let dropSnapshot;
    if (drop !== undefined && drop !== null) {
      if (
        typeof drop !== 'object' ||
        typeof drop.name !== 'string' ||
        !drop.name.trim() ||
        !isValidCoordinate(drop.latitude, drop.longitude)
      ) {
        return res.status(400).json({
          success: false,
          message:
            'Invalid drop location: name must be a non-empty string and coordinates must be valid (latitude -90..90, longitude -180..180)',
        });
      }
      dropSnapshot = {
        name: drop.name.trim(),
        latitude: drop.latitude,
        longitude: drop.longitude,
        point: {
          type: 'Point',
          coordinates: [drop.longitude, drop.latitude],
        },
      };
    } else {
      dropSnapshot = {
        name: ride.destination.name,
        latitude: ride.destination.latitude,
        longitude: ride.destination.longitude,
        point: ride.destination.point,
      };
    }

    // 6. Atomic Seat Capacity Reservation
    const updatedRide = await Ride.findOneAndUpdate(
      {
        _id: rideId,
        status: 'scheduled',
        availableSeats: { $gte: seats },
        departureTime: { $gt: new Date() },
      },
      {
        $inc: { availableSeats: -seats },
      },
      { new: true }
    );

    if (!updatedRide) {
      return res.status(409).json({
        success: false,
        message: 'Insufficient available seats or ride is no longer available',
      });
    }

    // 7. Calculate total contribution strictly on server side
    const contributionPerSeat = ride.contributionPerSeat;
    const totalContribution = seats * contributionPerSeat;

    // 8. Create booking record with duplicate race protection
    let booking;
    try {
      booking = await Booking.create({
        passenger: passengerId,
        ride: rideId,
        requestedSeats: seats,
        contributionPerSeat,
        totalContribution,
        status: 'pending',
        passengerNote: typeof passengerNote === 'string' ? passengerNote.trim() : '',
        pickup: pickupSnapshot,
        drop: dropSnapshot,
      });
    } catch (createErr) {
      // Rollback reserved seats if booking record creation fails
      await Ride.findByIdAndUpdate(rideId, { $inc: { availableSeats: seats } });

      // Handle duplicate active booking race caught by partial unique index
      if (createErr.code === 11000) {
        return res.status(409).json({
          success: false,
          message: 'You already have an active booking request for this ride',
        });
      }
      throw createErr;
    }

    // 9. Populate details for response
    const populatedBooking = await Booking.findById(booking._id)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar');

    res.status(201).json({
      success: true,
      message: 'Booking request submitted successfully (Pending Driver Approval)',
      data: populatedBooking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get passenger's own bookings
 * @route   GET /api/v1/bookings/my
 * @access  Private (Passenger)
 */
exports.getMyBookings = async (req, res, next) => {
  try {
    const passengerId = req.user.id;
    const query = { passenger: passengerId };

    if (req.query.status) {
      query.status = req.query.status;
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 10));
    const skip = (page - 1) * limit;

    const total = await Booking.countDocuments(query);

    const bookings = await Booking.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar');

    res.status(200).json({
      success: true,
      count: bookings.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: bookings,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get single booking by ID
 * @route   GET /api/v1/bookings/:id
 * @access  Private (Passenger or Driver of Ride)
 */
exports.getBookingById = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format',
      });
    }

    const booking = await Booking.findById(id)
      .populate({
        path: 'ride',
        select:
          'driver origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    const currentUserId = req.user.id.toString();
    const passengerId = booking.passenger._id
      ? booking.passenger._id.toString()
      : booking.passenger.toString();
    const driverId =
      booking.ride && booking.ride.driver && booking.ride.driver._id
        ? booking.ride.driver._id.toString()
        : booking.ride && booking.ride.driver
        ? booking.ride.driver.toString()
        : null;

    if (currentUserId !== passengerId && currentUserId !== driverId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view this booking',
      });
    }

    res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Cancel a pending booking request
 * @route   PATCH /api/v1/bookings/:id/cancel
 * @access  Private (Passenger)
 */
exports.cancelBooking = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format',
      });
    }

    const currentUserId = req.user.id.toString();

    // 1. Atomic status transition: only allow if booking is currently pending and owned by current user
    const updatedBooking = await Booking.findOneAndUpdate(
      {
        _id: id,
        passenger: currentUserId,
        status: 'pending',
      },
      {
        $set: { status: 'cancelled' },
      },
      { new: true }
    );

    if (!updatedBooking) {
      // Investigate why findOneAndUpdate did not match
      const existing = await Booking.findById(id);
      if (!existing) {
        return res.status(404).json({
          success: false,
          message: 'Booking not found',
        });
      }

      const passengerId = existing.passenger.toString();
      if (currentUserId !== passengerId) {
        return res.status(403).json({
          success: false,
          message: 'You are not authorized to cancel this booking',
        });
      }

      if (existing.status === 'cancelled') {
        return res.status(400).json({
          success: false,
          message: 'Booking request is already cancelled',
        });
      }

      return res.status(400).json({
        success: false,
        message: 'Only pending booking requests can be cancelled in this phase',
      });
    }

    // 2. Release reserved seats back to ride atomically
    await Ride.findByIdAndUpdate(updatedBooking.ride, {
      $inc: { availableSeats: updatedBooking.requestedSeats },
    });

    // 3. Populate response
    const populatedBooking = await Booking.findById(id)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar');

    res.status(200).json({
      success: true,
      message: 'Booking request cancelled successfully',
      data: populatedBooking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get booking requests for rides offered by the authenticated driver
 * @route   GET /api/v1/bookings/driver/requests
 * @access  Private (Driver)
 */
exports.getDriverBookingRequests = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { status, rideId, page = 1, limit = 20 } = req.query;

    // 1. Resolve target rides owned by driver
    let targetRideIds;
    if (rideId) {
      if (!mongoose.Types.ObjectId.isValid(rideId)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid ride ID format',
        });
      }
      const verifiedRide = await Ride.findOne({ _id: rideId, driver: driverId });
      if (!verifiedRide) {
        return res.status(403).json({
          success: false,
          message: 'You are not authorized to view booking requests for this ride',
        });
      }
      targetRideIds = [verifiedRide._id];
    } else {
      const driverRides = await Ride.find({ driver: driverId }).select('_id');
      targetRideIds = driverRides.map((r) => r._id);
    }

    if (targetRideIds.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        total: 0,
        page: Number(page),
        totalPages: 0,
        data: [],
      });
    }

    // 2. Query bookings belonging to driver's rides
    const query = { ride: { $in: targetRideIds } };
    if (status && typeof status === 'string' && status !== 'all') {
      query.status = status.toLowerCase();
    }

    const parsedPage = Math.max(1, parseInt(page, 10) || 1);
    const parsedLimit = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    const skip = (parsedPage - 1) * parsedLimit;

    const total = await Booking.countDocuments(query);
    const bookings = await Booking.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parsedLimit)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats bookedSeats pickupPolicy amenities notes',
        populate: [
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate(
        'passenger',
        'name phone email rating isVerified avatar profileImage'
      );

    res.status(200).json({
      success: true,
      count: bookings.length,
      total,
      page: parsedPage,
      totalPages: Math.ceil(total / parsedLimit),
      data: bookings,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Accept a pending booking request
 * @route   PATCH /api/v1/bookings/:id/accept
 * @access  Private (Driver owning the ride)
 */
exports.acceptBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const driverId = req.user.id.toString();

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format',
      });
    }

    // 1. Fetch booking with populated ride
    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    if (!booking.ride) {
      return res.status(404).json({
        success: false,
        message: 'Associated ride not found',
      });
    }

    // 2. Authorization: only ride owner can accept
    const rideDriverId = booking.ride.driver ? booking.ride.driver.toString() : null;
    if (rideDriverId !== driverId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to manage booking requests for this ride',
      });
    }

    // 3. Status check on booking
    if (booking.status === 'accepted') {
      return res.status(409).json({
        success: false,
        message: 'Booking request is already accepted',
      });
    }

    if (booking.status === 'rejected') {
      return res.status(409).json({
        success: false,
        message: 'Cannot accept a rejected booking request',
      });
    }

    if (booking.status === 'cancelled') {
      return res.status(409).json({
        success: false,
        message: 'Cannot accept a cancelled booking request',
      });
    }

    if (booking.status !== 'pending') {
      return res.status(409).json({
        success: false,
        message: `Cannot accept booking with status ${booking.status}`,
      });
    }

    // 4. Status check on ride
    if (booking.ride.status === 'cancelled') {
      return res.status(409).json({
        success: false,
        message: 'Cannot accept booking on a cancelled ride',
      });
    }

    if (booking.ride.status === 'completed') {
      return res.status(409).json({
        success: false,
        message: 'Cannot accept booking on a completed ride',
      });
    }

    if (new Date(booking.ride.departureTime) <= new Date()) {
      return res.status(409).json({
        success: false,
        message: 'Cannot accept booking on a departed ride',
      });
    }

    // 5. Atomic state transition: pending -> accepted
    const updatedBooking = await Booking.findOneAndUpdate(
      {
        _id: id,
        status: 'pending',
      },
      {
        $set: { status: 'accepted' },
      },
      { new: true }
    );

    if (!updatedBooking) {
      return res.status(409).json({
        success: false,
        message: 'Booking request state conflict. Please refresh and try again.',
      });
    }

    // 6. Capacity accounting:
    // Follow existing Phase 8 model: availableSeats was already decremented on creation.
    // Therefore, do NOT decrement availableSeats again! Increment bookedSeats by requestedSeats.
    await Ride.findByIdAndUpdate(booking.ride._id, {
      $inc: { bookedSeats: booking.requestedSeats },
    });

    // 7. Populate response
    const populatedBooking = await Booking.findById(id)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats bookedSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar profileImage' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar profileImage');

    res.status(200).json({
      success: true,
      message: 'Booking request accepted successfully',
      data: populatedBooking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reject a pending booking request
 * @route   PATCH /api/v1/bookings/:id/reject
 * @access  Private (Driver owning the ride)
 */
exports.rejectBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const driverId = req.user.id.toString();

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format',
      });
    }

    // 1. Fetch booking with populated ride
    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    if (!booking.ride) {
      return res.status(404).json({
        success: false,
        message: 'Associated ride not found',
      });
    }

    // 2. Authorization: only ride owner can reject
    const rideDriverId = booking.ride.driver ? booking.ride.driver.toString() : null;
    if (rideDriverId !== driverId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to manage booking requests for this ride',
      });
    }

    // 3. Status check on booking
    if (booking.status === 'accepted') {
      return res.status(409).json({
        success: false,
        message: 'Cannot reject an already accepted booking request',
      });
    }

    if (booking.status === 'rejected') {
      return res.status(409).json({
        success: false,
        message: 'Booking request is already rejected',
      });
    }

    if (booking.status === 'cancelled') {
      return res.status(409).json({
        success: false,
        message: 'Cannot reject a cancelled booking request',
      });
    }

    if (booking.status !== 'pending') {
      return res.status(409).json({
        success: false,
        message: `Cannot reject booking with status ${booking.status}`,
      });
    }

    // 4. Atomic state transition: pending -> rejected
    const updatedBooking = await Booking.findOneAndUpdate(
      {
        _id: id,
        status: 'pending',
      },
      {
        $set: { status: 'rejected' },
      },
      { new: true }
    );

    if (!updatedBooking) {
      return res.status(409).json({
        success: false,
        message: 'Booking request state conflict. Please refresh and try again.',
      });
    }

    // 5. Capacity accounting:
    // Release reserved seats back to ride capacity
    await Ride.findByIdAndUpdate(booking.ride._id, {
      $inc: { availableSeats: booking.requestedSeats },
    });

    // 6. Populate response
    const populatedBooking = await Booking.findById(id)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats bookedSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar profileImage' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar profileImage');

    res.status(200).json({
      success: true,
      message: 'Booking request rejected successfully',
      data: populatedBooking,
    });
  } catch (error) {
    next(error);
  }
};
