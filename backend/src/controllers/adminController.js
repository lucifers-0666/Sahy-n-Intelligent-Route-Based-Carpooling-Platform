const mongoose = require('mongoose');
const User = require('../models/User');
const Ride = require('../models/Ride');
const Booking = require('../models/Booking');
const Vehicle = require('../models/Vehicle');
const Report = require('../models/Report');
const Notification = require('../models/Notification');

/**
 * @desc Get aggregated platform statistics for admin dashboard
 * @route GET /api/v1/admin/stats
 * @access Private (Admin only)
 */
exports.getAdminStats = async (req, res, next) => {
  try {
    const [
      totalUsers,
      verifiedDrivers,
      pendingVerifications,
      activeJourneys,
      scheduledRides,
      completedRides,
      completedBookings,
      openReports,
      contributionAggregation,
    ] = await Promise.all([
      User.countDocuments({ role: { $ne: 'admin' } }),
      User.countDocuments({ isVerified: true, 'capabilities.canDrive': true }),
      User.countDocuments({ 'driverProfile.onboardingStatus': 'submitted' }),
      Ride.countDocuments({ status: { $in: ['boarding', 'in_progress'] } }),
      Ride.countDocuments({ status: 'scheduled' }),
      Ride.countDocuments({ status: 'completed' }),
      Booking.countDocuments({ status: 'completed' }),
      Report.countDocuments({ status: { $in: ['open', 'investigating'] } }),
      Booking.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, totalFuelSplit: { $sum: '$totalContribution' } } },
      ]),
    ]);

    const totalFuelSplit = contributionAggregation.length > 0 ? contributionAggregation[0].totalFuelSplit : 0;
    // Calculation: average pooled ride saves ~4.2 kg CO2 per completed passenger booking
    const totalCo2SavedKg = Math.round(completedBookings * 4.2 * 10) / 10;

    return res.status(200).json({
      success: true,
      data: {
        totalUsers,
        verifiedDrivers,
        pendingVerifications,
        activeJourneys,
        scheduledRides,
        completedRides,
        completedBookings,
        openReports,
        totalFuelSplit,
        totalCo2SavedKg,
        systemHealth: {
          database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
          uptimeSeconds: Math.floor(process.uptime()),
          apiVersion: '1.0.0',
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get paginated list of users with verification filters
 * @route GET /api/v1/admin/users
 * @access Private (Admin only)
 */
exports.getUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status = 'all', search } = req.query;
    const filter = { role: { $ne: 'admin' } };

    if (status === 'pending') {
      filter['driverProfile.onboardingStatus'] = 'submitted';
    } else if (status === 'verified') {
      filter.isVerified = true;
    } else if (status === 'rejected') {
      filter['driverProfile.onboardingStatus'] = 'rejected';
    } else if (status === 'drivers') {
      filter['capabilities.canDrive'] = true;
    }

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [users, total] = await Promise.all([
      User.find(filter)
        .select('-otpInfo')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit, 10)),
      User.countDocuments(filter),
    ]);

    // Attach vehicles for users if any
    const userIds = users.map((u) => u._id);
    const vehicles = await Vehicle.find({ owner: { $in: userIds } });
    const vehicleMap = {};
    vehicles.forEach((v) => {
      vehicleMap[v.owner.toString()] = v;
    });

    const enrichedUsers = users.map((u) => {
      const userObj = u.toObject();
      userObj.vehicle = vehicleMap[u._id.toString()] || null;
      return userObj;
    });

    return res.status(200).json({
      success: true,
      data: {
        users: enrichedUsers,
        pagination: {
          total,
          page: parseInt(page, 10),
          pages: Math.ceil(total / parseInt(limit, 10)),
          limit: parseInt(limit, 10),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Approve or reject a driver's verification
 * @route PATCH /api/v1/admin/users/:id/verify
 * @access Private (Admin only)
 */
exports.verifyDriver = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, reason = '' } = req.body;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status must be either "approved" or "rejected".',
      });
    }

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    if (status === 'approved') {
      user.isVerified = true;
      user.capabilities.canDrive = true;
      user.driverProfile.onboardingStatus = 'approved';
      user.driverProfile.verifiedAt = new Date();
      user.driverProfile.rejectionReason = '';

      await user.save();

      // Trigger user notification
      await Notification.create({
        user: user._id,
        title: 'Driver Verification Approved! 🎉',
        message: 'Your documents have been verified. You can now publish and share carpool journeys on Sahyān.',
        category: 'system',
        routeTarget: '/vehicles',
      });
    } else {
      user.isVerified = false;
      user.driverProfile.onboardingStatus = 'rejected';
      user.driverProfile.rejectionReason = reason || 'Documentation failed verification checks.';

      await user.save();

      // Trigger user notification
      await Notification.create({
        user: user._id,
        title: 'Driver Verification Update',
        message: `Your driver verification was not approved. Reason: ${reason || 'Document criteria not met.'}`,
        category: 'system',
        routeTarget: '/profile',
      });
    }

    return res.status(200).json({
      success: true,
      message: `Driver verification ${status} successfully.`,
      data: {
        user: {
          id: user._id,
          name: user.name,
          isVerified: user.isVerified,
          canDrive: user.capabilities.canDrive,
          onboardingStatus: user.driverProfile.onboardingStatus,
          rejectionReason: user.driverProfile.rejectionReason,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get paginated list of rides for moderation
 * @route GET /api/v1/admin/rides
 * @access Private (Admin only)
 */
exports.getRides = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status = 'all', search } = req.query;
    const filter = {};

    if (status !== 'all') {
      filter.status = status;
    }

    if (search) {
      filter.$or = [
        { 'origin.name': { $regex: search, $options: 'i' } },
        { 'destination.name': { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [rides, total] = await Promise.all([
      Ride.find(filter)
        .populate('driver', 'name phone email rating isVerified')
        .populate('vehicle', 'make model registrationNumber vehicleType')
        .sort({ departureTime: -1 })
        .skip(skip)
        .limit(parseInt(limit, 10)),
      Ride.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      data: {
        rides,
        pagination: {
          total,
          page: parseInt(page, 10),
          pages: Math.ceil(total / parseInt(limit, 10)),
          limit: parseInt(limit, 10),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Moderate/cancel a ride by admin
 * @route PATCH /api/v1/admin/rides/:id/moderate
 * @access Private (Admin only)
 */
exports.moderateRide = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { action = 'cancel', reason = 'Admin moderation policy' } = req.body;

    const ride = await Ride.findById(id);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found.',
      });
    }

    if (action === 'cancel') {
      ride.status = 'cancelled';
      await ride.save();

      // Cancel associated bookings
      await Booking.updateMany(
        { ride: ride._id, status: { $in: ['pending', 'confirmed'] } },
        { $set: { status: 'cancelled' } }
      );

      // Notify driver
      await Notification.create({
        user: ride.driver,
        title: 'Ride Cancelled by Admin',
        message: `Your scheduled ride from ${ride.origin.name} to ${ride.destination.name} was cancelled by admin: ${reason}`,
        category: 'safety',
      });
    }

    await ride.populate([
      { path: 'vehicle' },
      { path: 'driver', select: 'name email phone rating isVerified' },
    ]);

    return res.status(200).json({
      success: true,
      message: `Ride ${action === 'cancel' ? 'cancelled' : 'flagged'} successfully.`,
      data: { ride },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get safety reports, SOS alerts, and flags
 * @route GET /api/v1/admin/reports
 * @access Private (Admin only)
 */
exports.getReports = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status = 'all', type } = req.query;
    const filter = {};

    if (status !== 'all') {
      filter.status = status;
    }
    if (type) {
      filter.type = type;
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [reports, total] = await Promise.all([
      Report.find(filter)
        .populate('reporter', 'name phone email')
        .populate('reportedUser', 'name phone email')
        .populate('ride', 'origin destination departureTime status')
        .populate('resolvedBy', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit, 10)),
      Report.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      data: {
        reports,
        pagination: {
          total,
          page: parseInt(page, 10),
          pages: Math.ceil(total / parseInt(limit, 10)),
          limit: parseInt(limit, 10),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Resolve or dismiss a safety report
 * @route PATCH /api/v1/admin/reports/:id/resolve
 * @access Private (Admin only)
 */
exports.resolveReport = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status = 'resolved', notes = '' } = req.body;

    if (!['resolved', 'dismissed', 'investigating'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be resolved, dismissed, or investigating.',
      });
    }

    const report = await Report.findById(id);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found.',
      });
    }

    report.status = status;
    report.resolutionNotes = notes;
    if (status === 'resolved' || status === 'dismissed') {
      report.resolvedBy = req.user._id;
      report.resolvedAt = new Date();
    }

    await report.save();

    return res.status(200).json({
      success: true,
      message: `Report status updated to ${status}.`,
      data: { report },
    });
  } catch (error) {
    next(error);
  }
};
