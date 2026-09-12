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

    // 2. Release reserved seats back to ride atomically and safely
    const rideDoc = await Ride.findById(rideId);
    if (rideDoc) {
      const newAvailable = Math.min(rideDoc.totalSeats, rideDoc.availableSeats + requestedSeats);
      const updateOps = {
        $set: { availableSeats: newAvailable },
      };
      if (previousStatus === 'accepted') {
        updateOps.$set.bookedSeats = Math.max(0, rideDoc.bookedSeats - requestedSeats);
      }
      await Ride.findByIdAndUpdate(rideId, updateOps);
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
        const updatedBooking = await Booking.findOneAndUpdate(
          {
            _id: id,
            status: 'pending',
          },
          {
            $set: { status: 'accepted' },
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

