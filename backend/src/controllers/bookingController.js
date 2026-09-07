const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const Ride = require('../models/Ride');

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

    const seats = parseInt(requestedSeats, 10);
    if (isNaN(seats) || seats < 1 || seats > 8) {
      return res.status(400).json({
        success: false,
        message: 'Requested seats must be an integer between 1 and 8',
      });
    }

    // 2. Fetch ride and verify basic availability
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

    // 4. Prevent duplicate active booking requests for same ride
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

    // 5. Atomic Seat Capacity Reservation
    // Uses findOneAndUpdate with availableSeats check to prevent race conditions
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

    // 6. Calculate total contribution strictly on server side
    const contributionPerSeat = ride.contributionPerSeat;
    const totalContribution = seats * contributionPerSeat;

    // 7. Prepare snapshot data for pickup and drop
    const pickupSnapshot = pickup && pickup.name && pickup.latitude && pickup.longitude
      ? {
          name: pickup.name,
          latitude: pickup.latitude,
          longitude: pickup.longitude,
          point: {
            type: 'Point',
            coordinates: [pickup.longitude, pickup.latitude],
          },
        }
      : {
          name: ride.origin.name,
          latitude: ride.origin.latitude,
          longitude: ride.origin.longitude,
          point: ride.origin.point,
        };

    const dropSnapshot = drop && drop.name && drop.latitude && drop.longitude
      ? {
          name: drop.name,
          latitude: drop.latitude,
          longitude: drop.longitude,
          point: {
            type: 'Point',
            coordinates: [drop.longitude, drop.latitude],
          },
        }
      : {
          name: ride.destination.name,
          latitude: ride.destination.latitude,
          longitude: ride.destination.longitude,
          point: ride.destination.point,
        };

    // 8. Create booking record
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
      throw createErr;
    }

    // 9. Populate details for response
    const populatedBooking = await Booking.findById(booking._id)
      .populate({
        path: 'ride',
        select: 'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
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
        select: 'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
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
        select: 'driver origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
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
    const driverId = booking.ride.driver && booking.ride.driver._id
      ? booking.ride.driver._id.toString()
      : booking.ride.driver
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

    const booking = await Booking.findById(id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    const currentUserId = req.user.id.toString();
    const passengerId = booking.passenger.toString();

    if (currentUserId !== passengerId) {
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

    if (booking.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Only pending booking requests can be cancelled in this phase',
      });
    }

    // Update status to cancelled
    await Booking.findByIdAndUpdate(id, { status: 'cancelled' });

    // Release reserved seats back to ride
    await Ride.findByIdAndUpdate(booking.ride, {
      $inc: { availableSeats: booking.requestedSeats },
    });

    const populatedBooking = await Booking.findById(id)
      .populate({
        path: 'ride',
        select: 'origin destination departureTime estimatedArrivalTime contributionPerSeat status availableSeats totalSeats pickupPolicy amenities notes',
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
