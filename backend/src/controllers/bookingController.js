const crypto = require('crypto');
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const Ride = require('../models/Ride');
const User = require('../models/User');
const PaymentTransaction = require('../models/PaymentTransaction');
const AuditLog = require('../models/AuditLog');
const Report = require('../models/Report');
const FraudDetectionService = require('../services/fraudDetectionService');

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
    const passengerId = req.user.id || req.user._id;
    const { rideId, requestedSeats, passengerNote, pickup, drop, paymentMethod = 'cash', idempotencyKey } = req.body;

    // Idempotency check: Return existing booking if previously created with this key
    if (idempotencyKey && typeof idempotencyKey === 'string') {
      const existingIdempotentBooking = await Booking.findOne({
        passenger: passengerId,
        idempotencyKey: idempotencyKey.trim(),
      });
      if (existingIdempotentBooking) {
        return res.status(200).json({
          success: true,
          message: 'Booking request already processed (Idempotent replay)',
          data: existingIdempotentBooking,
        });
      }
    }

    // Check cash booking restrictions if cash selected
    if (paymentMethod === 'cash') {
      const passengerUser = await User.findById(passengerId);
      if (passengerUser && passengerUser.capabilities && passengerUser.capabilities.canBookCash === false) {
        return res.status(403).json({
          success: false,
          message: 'Cash payment is restricted on your account due to unresolved payment disputes. Please use an online payment method.',
        });
      }
    }

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
      const validPaymentMethod = ['cash', 'upi', 'card', 'netbanking', 'sandbox'].includes(paymentMethod)
        ? paymentMethod
        : 'cash';
      const paymentTypeSnapshot = validPaymentMethod === 'cash' ? 'cash_on_boarding' : 'online_escrow';

      const cancellationPolicySnapshot = ride.cancellationPolicy || {
        policyType: 'moderate',
        description: 'Free cancellation up to 2 hours before scheduled departure.',
        acceptedAt: new Date(),
      };

      booking = await Booking.create({
        passenger: passengerId,
        ride: rideId,
        requestedSeats: seats,
        contributionPerSeat,
        totalContribution,
        status: 'pending',
        paymentMethod: validPaymentMethod,
        paymentType: paymentTypeSnapshot,
        paymentStatus: 'pending',
        cancellationPolicy: cancellationPolicySnapshot,
        idempotencyKey: idempotencyKey ? String(idempotencyKey).trim() : null,
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
 * @desc    Cancel a booking request (pending or confirmed/accepted)
 * @route   PATCH /api/v1/bookings/:id/cancel
 * @access  Private (Passenger who booked or Driver of the ride)
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

    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    const passengerId = booking.passenger ? booking.passenger.toString() : '';
    const driverId = booking.ride && booking.ride.driver ? booking.ride.driver.toString() : '';

    if (currentUserId !== passengerId && currentUserId !== driverId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to cancel this booking',
      });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Booking request is already cancelled',
      });
    }

    if (booking.status === 'rejected') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a rejected booking request',
      });
    }

    if (booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a completed booking',
      });
    }

    if (booking.status !== 'pending' && booking.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel booking with status '${booking.status}'`,
      });
    }

    const previousStatus = booking.status;
    const requestedSeats = booking.requestedSeats;
    const rideId = booking.ride._id || booking.ride;

    // 1. Atomic status transition
    const updatedBooking = await Booking.findOneAndUpdate(
      {
        _id: id,
        status: previousStatus,
      },
      {
        $set: { status: 'cancelled' },
      },
      { new: true }
    );

    if (!updatedBooking) {
      return res.status(409).json({
        success: false,
        message: 'Booking state conflict. Please refresh and try again.',
      });
    }

    // 2. Release reserved seats back to ride atomically and safely via atomic aggregation pipeline
    const updatePipeline = [
      {
        $set: {
          availableSeats: {
            $min: ['$totalSeats', { $add: ['$availableSeats', requestedSeats] }],
          },
          ...(previousStatus === 'accepted'
            ? {
                bookedSeats: {
                  $max: [0, { $subtract: ['$bookedSeats', requestedSeats] }],
                },
              }
            : {}),
        },
      },
    ];

    try {
      await Ride.updateOne({ _id: rideId }, updatePipeline);
    } catch (rideErr) {
      await Booking.findByIdAndUpdate(id, { $set: { status: previousStatus } });
      throw rideErr;
    }

    // 3. Settle payment transaction and refund escrow if booking was paid
    if (booking.paymentStatus === 'paid') {
      try {
        await Booking.updateOne({ _id: id }, { $set: { paymentStatus: 'refunded' } });
        await PaymentTransaction.updateMany(
          { bookingId: id, status: { $in: ['pending', 'escrow_held'] } },
          { $set: { status: 'refunded' } }
        );
      } catch (payErr) {
        console.error('Failed to settle payment refund for cancelled booking:', payErr);
        throw payErr;
      }
    }

    // 3. Populate response
    const populatedBooking = await Booking.findById(id)
      .populate({
        path: 'ride',
        select:
          'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats bookedSeats pickupPolicy amenities notes',
        populate: [
          { path: 'driver', select: 'name phone email rating isVerified avatar' },
          { path: 'vehicle', select: 'make model year color registrationNumber vehicleType' },
        ],
      })
      .populate('passenger', 'name phone email rating isVerified avatar');

    return res.status(200).json({
      success: true,
      message: 'Booking request cancelled successfully',
      data: populatedBooking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update booking status (accept/confirm or reject)
 * @route   PATCH /api/v1/bookings/:id/status
 * @access  Private (Driver owning the ride)
 */
exports.updateBookingStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!status || typeof status !== 'string') {
      return res.status(400).json({
        success: false,
        message: "Status is required in request body (e.g. 'accepted', 'confirmed', or 'rejected')",
      });
    }

    const normalizedStatus = status.toLowerCase().trim();
    if (normalizedStatus === 'accepted' || normalizedStatus === 'confirmed') {
      return exports.acceptBooking(req, res, next);
    } else if (normalizedStatus === 'rejected') {
      return exports.rejectBooking(req, res, next);
    } else {
      return res.status(400).json({
        success: false,
        message: "Invalid status. Allowed values are 'accepted', 'confirmed', or 'rejected'",
      });
    }
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

    // 1. Parameter validations
    if (req.query.page !== undefined) {
      const parsed = parseInt(req.query.page, 10);
      if (isNaN(parsed) || parsed < 1) {
        return res.status(400).json({
          success: false,
          message: 'Invalid page parameter: must be a positive integer',
        });
      }
    }
    if (req.query.limit !== undefined) {
      const parsed = parseInt(req.query.limit, 10);
      if (isNaN(parsed) || parsed < 1) {
        return res.status(400).json({
          success: false,
          message: 'Invalid limit parameter: must be a positive integer',
        });
      }
    }

    // 2. Resolve target rides owned by driver
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
        page: Number(page) || 1,
        totalPages: 0,
        data: [],
      });
    }

    // 3. Query bookings belonging to driver's rides with status validation
    const query = { ride: { $in: targetRideIds } };
    if (status !== undefined && status !== null && status !== '') {
      if (typeof status !== 'string') {
        return res.status(400).json({
          success: false,
          message: 'Invalid status parameter format',
        });
      }
      const normalizedStatus = status.toLowerCase().trim();
      const validStatuses = ['pending', 'accepted', 'rejected', 'cancelled', 'completed', 'all'];
      if (!validStatuses.includes(normalizedStatus)) {
        return res.status(400).json({
          success: false,
          message: `Invalid status filter. Allowed values: ${validStatuses.join(', ')}`,
        });
      }
      if (normalizedStatus !== 'all') {
        query.status = normalizedStatus;
      }
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
  let session = null;
  try {
    const { id } = req.params;
    const driverId = req.user.id.toString();

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format',
      });
    }

    // Attempt Mongoose session transaction where supported (e.g. Atlas / Replica Set)
    let useTransaction = false;
    try {
      session = await mongoose.startSession();
      session.startTransaction();
      useTransaction = true;
    } catch (_) {
      if (session) {
        try {
          await session.endSession();
        } catch (e) {}
        session = null;
      }
      useTransaction = false;
    }

    if (useTransaction) {
      try {
        // 1. Fetch booking inside session
        const booking = await Booking.findById(id).session(session);
        if (!booking) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(404).json({
            success: false,
            message: 'Booking not found',
          });
        }

        if (!booking.ride) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(404).json({
            success: false,
            message: 'Associated ride not found',
          });
        }

        // 2. Fetch ride inside session
        const ride = await Ride.findById(booking.ride).session(session);
        if (!ride) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(404).json({
            success: false,
            message: 'Associated ride not found',
          });
        }

        // 3. Authorization check: only ride owner can accept
        const rideDriverId = ride.driver ? ride.driver.toString() : null;
        if (rideDriverId !== driverId) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(403).json({
            success: false,
            message: 'You are not authorized to manage booking requests for this ride',
          });
        }

        // 4. Status checks on booking
        if (booking.status === 'accepted') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Booking request is already accepted',
          });
        }

        if (booking.status === 'rejected') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot accept a rejected booking request',
          });
        }

        if (booking.status === 'cancelled') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot accept a cancelled booking request',
          });
        }

        if (booking.status === 'completed') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot accept a completed booking',
          });
        }

        if (booking.status !== 'pending') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: `Cannot accept booking with status ${booking.status}`,
          });
        }

        // 5. Status checks on ride
        if (ride.status === 'cancelled') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot accept booking on a cancelled ride',
          });
        }

        if (ride.status === 'completed') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot accept booking on a completed ride',
          });
        }

        if (new Date(ride.departureTime) <= new Date()) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot accept booking on a departed ride',
          });
        }

        // 6. Transition booking status pending -> accepted atomically inside session
        const boardingPin = crypto.randomInt(1000, 10000).toString();
        const boardingPinExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        const updatedBooking = await Booking.findOneAndUpdate(
          {
            _id: id,
            status: 'pending',
          },
          {
            $set: {
              status: 'accepted',
              boardingPin,
              boardingPinExpiresAt,
              boardingPinAttempts: 0,
              boardingPinLocked: false,
            },
          },
          { new: true, session }
        );

        if (!updatedBooking) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Booking request state conflict. Please refresh and try again.',
          });
        }

        // 7. Increment ride bookedSeats atomically inside session
        // (Following Phase 8 model: availableSeats was already decremented on creation)
        await Ride.findByIdAndUpdate(
          ride._id,
          {
            $inc: { bookedSeats: booking.requestedSeats },
          },
          { session }
        );

        // Commit transaction
        await session.commitTransaction();
        await session.endSession();
        session = null;
      } catch (txErr) {
        if (session) {
          try {
            await session.abortTransaction();
          } catch (_) {}
          try {
            await session.endSession();
          } catch (_) {}
          session = null;
        }

        // Handle MongoDB WriteConflict or transient transaction conflict
        if (
          txErr.code === 112 ||
          txErr.codeName === 'WriteConflict' ||
          (txErr.message && txErr.message.includes('WriteConflict')) ||
          (typeof txErr.hasErrorLabel === 'function' && txErr.hasErrorLabel('TransientTransactionError'))
        ) {
          return res.status(409).json({
            success: false,
            message: 'Booking request state conflict. Please refresh and try again.',
          });
        }

        const isTxUnsupported =
          txErr.message &&
          (txErr.message.includes('replica set') ||
            txErr.message.includes('Transaction numbers are only allowed') ||
            txErr.message.includes('This MongoDB deployment does not support'));

        if (!isTxUnsupported) {
          throw txErr;
        }

        useTransaction = false;
      }
    }

    if (!useTransaction) {
      // Safest compatible strategy for non-replica-set standalone environments:
      // Conditional atomic updates with rollback compensation
      const booking = await Booking.findById(id);
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

      const ride = await Ride.findById(booking.ride);
      if (!ride) {
        return res.status(404).json({
          success: false,
          message: 'Associated ride not found',
        });
      }

      const rideDriverId = ride.driver ? ride.driver.toString() : null;
      if (rideDriverId !== driverId) {
        return res.status(403).json({
          success: false,
          message: 'You are not authorized to manage booking requests for this ride',
        });
      }

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

      if (booking.status === 'completed') {
        return res.status(409).json({
          success: false,
          message: 'Cannot accept a completed booking',
        });
      }

      if (booking.status !== 'pending') {
        return res.status(409).json({
          success: false,
          message: `Cannot accept booking with status ${booking.status}`,
        });
      }

      if (ride.status === 'cancelled') {
        return res.status(409).json({
          success: false,
          message: 'Cannot accept booking on a cancelled ride',
        });
      }

      if (ride.status === 'completed') {
        return res.status(409).json({
          success: false,
          message: 'Cannot accept booking on a completed ride',
        });
      }

      if (new Date(ride.departureTime) <= new Date()) {
        return res.status(409).json({
          success: false,
          message: 'Cannot accept booking on a departed ride',
        });
      }

      const boardingPin = crypto.randomInt(1000, 10000).toString();
      const boardingPinExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

      const updatedBooking = await Booking.findOneAndUpdate(
        {
          _id: id,
          status: 'pending',
        },
        {
          $set: {
            status: 'accepted',
            boardingPin,
            boardingPinExpiresAt,
            boardingPinAttempts: 0,
            boardingPinLocked: false,
          },
        },
        { new: true }
      );

      if (!updatedBooking) {
        return res.status(409).json({
          success: false,
          message: 'Booking request state conflict. Please refresh and try again.',
        });
      }

      try {
        await Ride.findByIdAndUpdate(ride._id, {
          $inc: { bookedSeats: booking.requestedSeats },
        });
      } catch (rideErr) {
        await Booking.findByIdAndUpdate(id, { $set: { status: 'pending' } });
        throw rideErr;
      }
    }

    // Populate response
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

    return res.status(200).json({
      success: true,
      message: 'Booking request accepted successfully',
      data: populatedBooking,
    });
  } catch (error) {
    if (session) {
      try {
        await session.abortTransaction();
      } catch (_) {}
      try {
        await session.endSession();
      } catch (_) {}
    }
    next(error);
  }
};

/**
 * @desc    Reject a pending booking request
 * @route   PATCH /api/v1/bookings/:id/reject
 * @access  Private (Driver owning the ride)
 */
exports.rejectBooking = async (req, res, next) => {
  let session = null;
  try {
    const { id } = req.params;
    const driverId = req.user.id.toString();

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format',
      });
    }

    // Attempt Mongoose session transaction where supported
    let useTransaction = false;
    try {
      session = await mongoose.startSession();
      session.startTransaction();
      useTransaction = true;
    } catch (_) {
      if (session) {
        try {
          await session.endSession();
        } catch (e) {}
        session = null;
      }
      useTransaction = false;
    }

    if (useTransaction) {
      try {
        // 1. Fetch booking inside session
        const booking = await Booking.findById(id).session(session);
        if (!booking) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(404).json({
            success: false,
            message: 'Booking not found',
          });
        }

        if (!booking.ride) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(404).json({
            success: false,
            message: 'Associated ride not found',
          });
        }

        // 2. Fetch ride inside session
        const ride = await Ride.findById(booking.ride).session(session);
        if (!ride) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(404).json({
            success: false,
            message: 'Associated ride not found',
          });
        }

        // 3. Authorization check: only ride owner can reject
        const rideDriverId = ride.driver ? ride.driver.toString() : null;
        if (rideDriverId !== driverId) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(403).json({
            success: false,
            message: 'You are not authorized to manage booking requests for this ride',
          });
        }

        // 4. Status checks on booking
        if (booking.status === 'accepted') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot reject an already accepted booking request',
          });
        }

        if (booking.status === 'rejected') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Booking request is already rejected',
          });
        }

        if (booking.status === 'cancelled') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot reject a cancelled booking request',
          });
        }

        if (booking.status === 'completed') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Cannot reject a completed booking',
          });
        }

        if (booking.status !== 'pending') {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: `Cannot reject booking with status ${booking.status}`,
          });
        }

        // 5. Atomic state transition inside session
        const updatedBooking = await Booking.findOneAndUpdate(
          {
            _id: id,
            status: 'pending',
          },
          {
            $set: { status: 'rejected' },
          },
          { new: true, session }
        );

        if (!updatedBooking) {
          await session.abortTransaction();
          await session.endSession();
          return res.status(409).json({
            success: false,
            message: 'Booking request state conflict. Please refresh and try again.',
          });
        }

        // 6. Release reserved seats back to ride capacity inside session
        await Ride.findByIdAndUpdate(
          ride._id,
          {
            $inc: { availableSeats: booking.requestedSeats },
          },
          { session }
        );

        await session.commitTransaction();
        await session.endSession();
        session = null;
      } catch (txErr) {
        if (session) {
          try {
            await session.abortTransaction();
          } catch (_) {}
          try {
            await session.endSession();
          } catch (_) {}
          session = null;
        }

        // Handle MongoDB WriteConflict or transient transaction conflict
        if (
          txErr.code === 112 ||
          txErr.codeName === 'WriteConflict' ||
          (txErr.message && txErr.message.includes('WriteConflict')) ||
          (typeof txErr.hasErrorLabel === 'function' && txErr.hasErrorLabel('TransientTransactionError'))
        ) {
          return res.status(409).json({
            success: false,
            message: 'Booking request state conflict. Please refresh and try again.',
          });
        }

        const isTxUnsupported =
          txErr.message &&
          (txErr.message.includes('replica set') ||
            txErr.message.includes('Transaction numbers are only allowed') ||
            txErr.message.includes('This MongoDB deployment does not support'));

        if (!isTxUnsupported) {
          throw txErr;
        }

        useTransaction = false;
      }
    }

    if (!useTransaction) {
      // Safest compatible strategy for non-replica-set standalone environments
      const booking = await Booking.findById(id);
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

      const ride = await Ride.findById(booking.ride);
      if (!ride) {
        return res.status(404).json({
          success: false,
          message: 'Associated ride not found',
        });
      }

      const rideDriverId = ride.driver ? ride.driver.toString() : null;
      if (rideDriverId !== driverId) {
        return res.status(403).json({
          success: false,
          message: 'You are not authorized to manage booking requests for this ride',
        });
      }

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

      if (booking.status === 'completed') {
        return res.status(409).json({
          success: false,
          message: 'Cannot reject a completed booking',
        });
      }

      if (booking.status !== 'pending') {
        return res.status(409).json({
          success: false,
          message: `Cannot reject booking with status ${booking.status}`,
        });
      }

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

      try {
        await Ride.findByIdAndUpdate(ride._id, {
          $inc: { availableSeats: booking.requestedSeats },
        });
      } catch (rideErr) {
        await Booking.findByIdAndUpdate(id, { $set: { status: 'pending' } });
        throw rideErr;
      }
    }

    // Populate response
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

    return res.status(200).json({
      success: true,
      message: 'Booking request rejected successfully',
      data: populatedBooking,
    });
  } catch (error) {
    if (session) {
      try {
        await session.abortTransaction();
      } catch (_) {}
      try {
        await session.endSession();
      } catch (_) {}
    }
    next(error);
  }
};

/**
 * @desc    Verify 4-digit boarding PIN presented by passenger at pickup
 * @route   POST /api/v1/bookings/:id/verify-pin
 * @access  Private (Ride Driver Only)
 */
exports.verifyBoardingPin = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { pin } = req.body;
    const driverId = (req.user._id || req.user.id).toString();

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid booking ID format' });
    }

    if (!pin || typeof pin !== 'string' || pin.trim().length !== 4) {
      return res.status(400).json({ success: false, message: 'A 4-digit boarding PIN is required' });
    }

    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (!booking.ride || booking.ride.driver.toString() !== driverId) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized: Only the designated ride driver can verify boarding PIN',
      });
    }

    if (booking.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: `Cannot verify boarding for booking with status '${booking.status}'`,
      });
    }

    if (booking.boardedAt) {
      return res.status(400).json({
        success: false,
        message: 'Passenger has already boarded',
      });
    }

    if (booking.boardingPinLocked) {
      return res.status(403).json({
        success: false,
        message: 'Boarding PIN is locked due to too many failed attempts. Please contact support.',
      });
    }

    if (booking.boardingPinExpiresAt && new Date(booking.boardingPinExpiresAt) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Boarding PIN has expired. Driver must re-request verification.',
      });
    }

    const trimmedPin = pin.trim();
    if (booking.boardingPin !== trimmedPin) {
      const attempts = (booking.boardingPinAttempts || 0) + 1;
      const isLocked = attempts >= 5;

      booking.boardingPinAttempts = attempts;
      if (isLocked) {
        booking.boardingPinLocked = true;
      }
      await booking.save();

      await AuditLog.create({
        action: isLocked ? 'BOARDING_PIN_LOCKED' : 'BOARDING_PIN_FAILED',
        actorRole: 'driver',
        admin: driverId,
        targetUser: booking.passenger,
        bookingId: booking._id,
        rideId: booking.ride._id,
        reason: isLocked
          ? '5 consecutive invalid PIN attempts. Boarding PIN locked.'
          : `Invalid PIN attempt (${attempts}/5)`,
      });

      if (isLocked) {
        return res.status(403).json({
          success: false,
          message: 'Maximum verification attempts exceeded. Boarding PIN is now locked.',
        });
      }

      return res.status(400).json({
        success: false,
        message: `Invalid boarding PIN. Remaining attempts: ${5 - attempts}`,
      });
    }

    // PIN is correct
    booking.boardedAt = new Date();
    booking.boardedBy = driverId;
    booking.boardingPinAttempts = 0;
    await booking.save();

    await AuditLog.create({
      action: 'BOARDING_PIN_VERIFIED',
      actorRole: 'driver',
      admin: driverId,
      targetUser: booking.passenger,
      bookingId: booking._id,
      rideId: booking.ride._id,
      reason: 'Passenger successfully verified boarding PIN with driver.',
    });

    return res.status(200).json({
      success: true,
      message: 'Boarding PIN verified successfully. Passenger marked as boarded.',
      data: {
        bookingId: booking._id,
        boardedAt: booking.boardedAt,
        status: booking.status,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Driver confirms cash contribution receipt from passenger
 * @route   POST /api/v1/bookings/:id/confirm-cash
 * @access  Private (Ride Driver Only)
 */
exports.confirmCashPayment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const driverId = (req.user._id || req.user.id).toString();

    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (!booking.ride || booking.ride.driver.toString() !== driverId) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Driver mismatch' });
    }

    if (booking.paymentMethod !== 'cash') {
      return res.status(400).json({ success: false, message: 'Booking payment method is not cash' });
    }

    booking.paymentStatus = 'cash_collected';
    await booking.save();

    await AuditLog.create({
      action: 'CASH_PAYMENT_CONFIRMED',
      actorRole: 'driver',
      admin: driverId,
      targetUser: booking.passenger,
      bookingId: booking._id,
      rideId: booking.ride._id,
      reason: 'Driver confirmed receipt of cash contribution from passenger.',
    });

    return res.status(200).json({
      success: true,
      message: 'Cash payment confirmed successfully.',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Driver reports non-payment of cash contribution by passenger
 * @route   POST /api/v1/bookings/:id/report-unpaid
 * @access  Private (Ride Driver Only)
 */
exports.reportUnpaidCash = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    const driverId = (req.user._id || req.user.id).toString();

    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (!booking.ride || booking.ride.driver.toString() !== driverId) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Driver mismatch' });
    }

    if (booking.paymentMethod !== 'cash') {
      return res.status(400).json({
        success: false,
        message: 'Unpaid cash report can only be filed for cash bookings',
      });
    }

    booking.paymentStatus = 'unpaid_reported';
    booking.dispute = {
      status: 'unpaid_reported',
      driverReportedAt: new Date(),
      driverNotes: String(notes || 'Passenger failed to provide agreed cash contribution').trim(),
      passengerRespondedAt: null,
      passengerNotes: '',
      evidenceUrls: [],
    };
    await booking.save();

    // Trigger user fraud risk evaluation
    await FraudDetectionService.evaluateUserRisk(booking.passenger);

    await AuditLog.create({
      action: 'UNPAID_CASH_REPORTED',
      actorRole: 'driver',
      admin: driverId,
      targetUser: booking.passenger,
      bookingId: booking._id,
      rideId: booking.ride._id,
      reason: `Driver reported unpaid cash contribution: ${booking.dispute.driverNotes}`,
    });

    return res.status(200).json({
      success: true,
      message: 'Unpaid cash contribution reported. Recorded for safety review.',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Passenger disputes an unpaid cash allegation
 * @route   POST /api/v1/bookings/:id/dispute-unpaid
 * @access  Private (Passenger Only)
 */
exports.disputeUnpaidCash = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { notes, evidenceUrls = [] } = req.body;
    const passengerId = (req.user._id || req.user.id).toString();

    const booking = await Booking.findById(id);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (booking.passenger.toString() !== passengerId) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Passenger mismatch' });
    }

    if (!booking.dispute || booking.dispute.status !== 'unpaid_reported') {
      return res.status(400).json({
        success: false,
        message: 'No open unpaid report exists on this booking to dispute',
      });
    }

    booking.paymentStatus = 'disputed';
    booking.dispute.status = 'passenger_disputed';
    booking.dispute.passengerRespondedAt = new Date();
    booking.dispute.passengerNotes = String(notes || 'Passenger disputes non-payment allegation').trim();
    if (Array.isArray(evidenceUrls)) {
      booking.dispute.evidenceUrls = evidenceUrls;
    }
    await booking.save();

    await AuditLog.create({
      action: 'PAYMENT_DISPUTED',
      actorRole: 'user',
      admin: passengerId,
      targetUser: passengerId,
      bookingId: booking._id,
      rideId: booking.ride,
      reason: `Passenger submitted dispute against unpaid report: ${booking.dispute.passengerNotes}`,
    });

    return res.status(200).json({
      success: true,
      message: 'Dispute submitted successfully. Case initiated for administrative review.',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Submit a formal payment or ride dispute (Passenger or Driver)
 * @route   POST /api/v1/bookings/:id/dispute
 * @access  Private (Passenger or Driver)
 */
exports.disputeBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      reason,
      disputeType = 'service_issue',
      claimType = 'refund_request',
      evidenceUrls = [],
    } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    if (!reason || !String(reason).trim()) {
      return res.status(400).json({ success: false, message: 'Dispute reason is required' });
    }

    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const isPassenger = booking.passenger.toString() === userId;
    const isDriver = booking.ride && booking.ride.driver.toString() === userId;

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized: You are neither passenger nor driver for this booking',
      });
    }

    // Set dispute status on booking
    booking.paymentStatus = 'disputed';
    if (!booking.dispute) booking.dispute = {};
    booking.dispute.status = 'under_review';

    if (isPassenger) {
      booking.dispute.passengerRespondedAt = new Date();
      booking.dispute.passengerNotes = String(reason).trim();
    } else {
      booking.dispute.driverReportedAt = new Date();
      booking.dispute.driverNotes = String(reason).trim();
    }

    if (Array.isArray(evidenceUrls) && evidenceUrls.length > 0) {
      booking.dispute.evidenceUrls = evidenceUrls;
    }

    await booking.save();

    // Mark linked PaymentTransaction as disputed if exists
    let transaction = null;
    if (booking.paymentTransactionId) {
      transaction = await PaymentTransaction.findById(booking.paymentTransactionId);
      if (transaction) {
        transaction.status = 'disputed';
        await transaction.save();
      }
    } else {
      transaction = await PaymentTransaction.findOne({ bookingId: booking._id }).sort({ createdAt: -1 });
      if (transaction) {
        transaction.status = 'disputed';
        await transaction.save();
      }
    }

    // Create a formal administrative Report case
    const report = await Report.create({
      reporter: userId,
      reportedUser: isPassenger ? booking.ride?.driver : booking.passenger,
      ride: booking.ride ? booking.ride._id : null,
      booking: booking._id,
      transaction: transaction ? transaction._id : null,
      type: 'payment_dispute',
      title: `Dispute on Booking ${booking._id}: ${claimType}`,
      description: String(reason).trim(),
      severity: 'medium',
      status: 'open',
      evidence: Array.isArray(evidenceUrls)
        ? evidenceUrls.map((url) => ({ url, type: 'document', description: 'User dispute evidence' }))
        : [],
    });

    await AuditLog.create({
      action: 'PAYMENT_DISPUTED',
      actorRole: isPassenger ? 'passenger' : 'driver',
      admin: userId,
      targetUser: isPassenger ? booking.ride?.driver : booking.passenger,
      bookingId: booking._id,
      rideId: booking.ride ? booking.ride._id : null,
      reason: `Dispute initiated (${claimType}): ${reason}`,
      metadata: {
        disputeType,
        claimType,
        evidenceCount: Array.isArray(evidenceUrls) ? evidenceUrls.length : 0,
        reportId: report._id,
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Dispute submitted successfully. Case initiated for administrative review.',
      data: {
        booking,
        reportId: report._id,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Report passenger or driver no-show
 *          Never bans user automatically without administrative investigation
 * @route   POST /api/v1/bookings/:id/no-show
 * @access  Private (Passenger or Driver)
 */
exports.reportNoShow = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason = 'Party did not show up at designated pickup location', evidenceUrls = [] } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    const booking = await Booking.findById(id).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const isPassenger = booking.passenger.toString() === userId;
    const isDriver = booking.ride && booking.ride.driver.toString() === userId;

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized: You are neither passenger nor driver for this booking',
      });
    }

    if (booking.status === 'completed' || booking.status === 'cancelled') {
      return res.status(400).json({ success: false, message: `Cannot report no-show on ${booking.status} booking` });
    }

    if (isDriver) {
      // Driver reports passenger no-show
      booking.status = 'cancelled';
      if (!booking.dispute) booking.dispute = {};
      booking.dispute.status = 'no_show';
      booking.dispute.driverReportedAt = new Date();
      booking.dispute.driverNotes = String(reason).trim();
      if (Array.isArray(evidenceUrls)) booking.dispute.evidenceUrls = evidenceUrls;
      await booking.save();

      // Concurrency-safe seat release: If booking was accepted, release seat back to ride
      if (booking.ride) {
        await Ride.findByIdAndUpdate(booking.ride._id, {
          $inc: { availableSeats: booking.requestedSeats, bookedSeats: -booking.requestedSeats },
        });
      }

      await AuditLog.create({
        action: 'NO_SHOW_REPORTED',
        actorRole: 'driver',
        admin: userId,
        targetUser: booking.passenger,
        bookingId: booking._id,
        rideId: booking.ride ? booking.ride._id : null,
        reason: `Driver reported passenger no-show: ${reason}`,
      });

      return res.status(200).json({
        success: true,
        message: 'Passenger no-show recorded. Seat restored to ride capacity.',
        data: booking,
      });
    } else {
      // Passenger reports driver no-show: Flag for admin investigation
      if (!booking.dispute) booking.dispute = {};
      booking.dispute.status = 'under_review';
      booking.dispute.passengerRespondedAt = new Date();
      booking.dispute.passengerNotes = String(reason).trim();
      if (Array.isArray(evidenceUrls)) booking.dispute.evidenceUrls = evidenceUrls;
      await booking.save();

      const report = await Report.create({
        reporter: userId,
        reportedUser: booking.ride?.driver,
        ride: booking.ride ? booking.ride._id : null,
        booking: booking._id,
        type: 'no_show',
        title: `Passenger reported Driver No-Show on Ride ${booking.ride?._id}`,
        description: String(reason).trim(),
        severity: 'high',
        status: 'open',
      });

      await AuditLog.create({
        action: 'NO_SHOW_REPORTED',
        actorRole: 'passenger',
        admin: userId,
        targetUser: booking.ride?.driver,
        bookingId: booking._id,
        rideId: booking.ride ? booking.ride._id : null,
        reason: `Passenger reported driver no-show: ${reason}`,
        metadata: { reportId: report._id },
      });

      return res.status(200).json({
        success: true,
        message: 'Driver no-show reported. Case submitted for review without automatic penalties.',
        data: {
          booking,
          reportId: report._id,
        },
      });
    }
  } catch (error) {
    next(error);
  }
};


