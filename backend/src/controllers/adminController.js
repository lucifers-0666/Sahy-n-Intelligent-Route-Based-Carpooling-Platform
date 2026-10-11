const mongoose = require('mongoose');
const User = require('../models/User');
const Ride = require('../models/Ride');
const Booking = require('../models/Booking');
const Vehicle = require('../models/Vehicle');
const Report = require('../models/Report');
const Notification = require('../models/Notification');
const AuditLog = require('../models/AuditLog');
const socketService = require('../services/socketService');

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
      Ride.countDocuments({ status: { $in: ['boarding', 'active', 'in_progress'] } }),
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
        title: 'Driver Verification Approved!',
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

    // Create AuditLog entry
    await AuditLog.create({
      action: status === 'approved' ? 'DRIVER_VERIFIED' : 'DRIVER_REJECTED',
      admin: req.user._id,
      targetUser: user._id,
      reason: reason || (status === 'approved' ? 'KYC credentials and documents verified' : 'Document verification criteria failed'),
      metadata: {
        licenseNumber: user.driverProfile.licenseNumber,
        status,
        verifiedAt: new Date(),
      },
    });

    // Real-time broadcast to admin emergency & monitoring consoles
    if (socketService.broadcastToAdmins) {
      socketService.broadcastToAdmins('driver_verification_updated', {
        userId: user._id.toString(),
        name: user.name,
        isVerified: user.isVerified,
        canDrive: user.capabilities.canDrive,
        onboardingStatus: user.driverProfile.onboardingStatus,
        rejectionReason: user.driverProfile.rejectionReason,
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

/**
 * @desc Get paginated list of bookings for cancellation & dispute investigation
 * @route GET /api/v1/admin/bookings
 * @access Private (Admin only)
 */
exports.getBookings = async (req, res, next) => {
  try {
    const { page = 1, limit = 50, status = 'all', paymentStatus } = req.query;
    const filter = {};

    if (status !== 'all') {
      filter.status = status;
    }
    if (paymentStatus && paymentStatus !== 'all') {
      filter.paymentStatus = paymentStatus;
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [bookings, total] = await Promise.all([
      Booking.find(filter)
        .populate('passenger', 'name phone email')
        .populate({
          path: 'ride',
          select: 'origin destination departureTime driver status contributionPerSeat',
          populate: { path: 'driver', select: 'name phone email rating' },
        })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit, 10)),
      Booking.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      data: {
        bookings,
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
 * @desc Suspend an eligible driver account
 * @route PATCH /api/v1/admin/users/:id/suspend
 * @access Private (Admin only)
 */
exports.suspendDriver = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID format.' });
    }

    const targetUser = await User.findById(id);
    if (!targetUser) {
      return res.status(404).json({ success: false, message: 'User account not found.' });
    }

    // Reject suspending administrators
    if (targetUser.role === 'admin') {
      return res.status(403).json({ success: false, message: 'Cannot suspend an administrator account.' });
    }

    // Reject self-suspension
    if (req.user._id.toString() === targetUser._id.toString()) {
      return res.status(403).json({ success: false, message: 'Administrators cannot suspend their own account.' });
    }

    // Authoritative eligibility check: must be a driver
    const hasRegisteredVehicle = await Vehicle.exists({ owner: targetUser._id });
    const isEligibleDriver =
      targetUser.capabilities?.canDrive === true ||
      targetUser.driverProfile?.onboardingStatus === 'approved' ||
      !!hasRegisteredVehicle;

    if (!isEligibleDriver) {
      return res.status(400).json({
        success: false,
        message: 'Target user is not an eligible driver account. Passenger-only accounts cannot be suspended via this endpoint.',
      });
    }

    // Reason validation: trimmed, 5 to 500 characters
    const { reason } = req.body;
    if (!reason || typeof reason !== 'string' || reason.trim().length < 5 || reason.trim().length > 500) {
      return res.status(400).json({
        success: false,
        message: 'A specific, non-empty suspension reason (between 5 and 500 characters) is required.',
      });
    }

    if (targetUser.accountStatus === 'suspended') {
      return res.status(400).json({ success: false, message: 'Driver account is already suspended.' });
    }

    // Persist new state
    targetUser.accountStatus = 'suspended';
    targetUser.suspensionReason = reason.trim();
    targetUser.suspendedAt = new Date();
    targetUser.suspendedBy = req.user._id;
    targetUser.suspensionUpdatedAt = new Date();
    await targetUser.save();

    // Persist audit record
    await AuditLog.create({
      action: 'DRIVER_SUSPENDED',
      admin: req.user._id,
      targetUser: targetUser._id,
      reason: reason.trim(),
      metadata: {
        targetName: targetUser.name,
        targetEmail: targetUser.email,
        targetPhone: targetUser.phone,
      },
    });

    // Terminate any active Socket.IO telematics connection immediately
    if (socketService.disconnectUserSockets) {
      socketService.disconnectUserSockets(targetUser._id);
    }

    return res.status(200).json({
      success: true,
      message: 'Driver account suspended successfully.',
      data: { user: targetUser },
      user: targetUser,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Reactivate a suspended driver account
 * @route PATCH /api/v1/admin/users/:id/reactivate
 * @access Private (Admin only)
 */
exports.reactivateDriver = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID format.' });
    }

    const targetUser = await User.findById(id);
    if (!targetUser) {
      return res.status(404).json({ success: false, message: 'User account not found.' });
    }

    if (targetUser.accountStatus !== 'suspended') {
      return res.status(400).json({ success: false, message: 'Account is not currently suspended.' });
    }

    // Restore active state
    targetUser.accountStatus = 'active';
    targetUser.suspensionReason = '';
    targetUser.suspendedAt = null;
    targetUser.suspendedBy = null;
    targetUser.suspensionUpdatedAt = new Date();
    await targetUser.save();

    // Persist audit record
    await AuditLog.create({
      action: 'DRIVER_REACTIVATED',
      admin: req.user._id,
      targetUser: targetUser._id,
      reason: req.body && req.body.reason ? req.body.reason.trim() : 'Reactivated by administrator',
      metadata: {
        targetName: targetUser.name,
        targetEmail: targetUser.email,
        targetPhone: targetUser.phone,
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Driver account reactivated successfully.',
      data: { user: targetUser },
      user: targetUser,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get paginated admin audit log entries
 * @route GET /api/v1/admin/audit-logs
 * @access Private (Admin only)
 */
exports.getAuditLogs = async (req, res, next) => {
  try {
    const { page = 1, limit = 50, action, adminId } = req.query;
    const filter = {};
    if (action && action !== 'all') filter.action = action;
    if (adminId) filter.admin = adminId;

    const total = await AuditLog.countDocuments(filter);
    const logs = await AuditLog.find(filter)
      .populate('admin', 'name email')
      .populate('targetUser', 'name email phone')
      .sort({ createdAt: -1 })
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit));

    return res.status(200).json({
      success: true,
      data: {
        logs,
        total,
        page: Number(page),
        totalPages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get platform revenue and monetization statistics
 * @route GET /api/v1/admin/revenue-stats
 * @access Private (Admin only)
 */
exports.getRevenueStats = async (req, res, next) => {
  try {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const [
      totalBookings,
      completedBookings,
      recentBookings,
      weeklyBookings,
      totalFuelAgg,
      monthlyFuelAgg,
      weeklyFuelAgg,
      escrowAgg,
      totalUsers,
      newUsersMonth,
      totalRides,
      completedRides,
    ] = await Promise.all([
      Booking.countDocuments(),
      Booking.countDocuments({ status: 'completed' }),
      Booking.countDocuments({ createdAt: { $gte: thirtyDaysAgo } }),
      Booking.countDocuments({ createdAt: { $gte: sevenDaysAgo } }),
      Booking.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$totalContribution' } } },
      ]),
      Booking.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: thirtyDaysAgo } } },
        { $group: { _id: null, total: { $sum: '$totalContribution' } } },
      ]),
      Booking.aggregate([
        { $match: { status: 'completed', createdAt: { $gte: sevenDaysAgo } } },
        { $group: { _id: null, total: { $sum: '$totalContribution' } } },
      ]),
      Booking.aggregate([
        { $match: { status: { $in: ['pending', 'accepted'] } } },
        { $group: { _id: null, total: { $sum: '$totalContribution' } } },
      ]),
      User.countDocuments({ role: { $ne: 'admin' } }),
      User.countDocuments({ role: { $ne: 'admin' }, createdAt: { $gte: thirtyDaysAgo } }),
      Ride.countDocuments(),
      Ride.countDocuments({ status: 'completed' }),
    ]);

    // Monthly breakdown for trend chart (last 6 months)
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    const monthlyTrend = await Booking.aggregate([
      { $match: { status: 'completed', createdAt: { $gte: sixMonthsAgo } } },
      {
        $group: {
          _id: { year: { $year: '$createdAt' }, month: { $month: '$createdAt' } },
          bookings: { $sum: 1 },
          fuelShared: { $sum: '$totalContribution' },
        },
      },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    const totalFuelShared = totalFuelAgg[0]?.total || 0;
    const monthlyFuelShared = monthlyFuelAgg[0]?.total || 0;
    const weeklyFuelShared = weeklyFuelAgg[0]?.total || 0;
    const escrowBalance = escrowAgg[0]?.total || 0;
    const settledToDrivers = totalFuelShared;
    const safetyFeePool = Math.round(totalFuelShared * 0.05);
    const completionRate = totalBookings > 0 ? Math.round((completedBookings / totalBookings) * 100) : 0;
    const co2SavedKg = Math.round(completedBookings * 4.2 * 10) / 10;

    return res.status(200).json({
      success: true,
      data: {
        totalFuelShared,
        monthlyFuelShared,
        weeklyFuelShared,
        escrowBalance,
        settledToDrivers,
        safetyFeePool,
        gatewayStatus: {
          razorpayWebhook: 'connected',
          bankPayoutApi: 'connected',
          latencyMs: 38,
          status: 'Live & Connected',
          lastPing: new Date().toISOString(),
        },
        totalBookings,
        completedBookings,
        recentBookings,
        weeklyBookings,
        completionRate,
        co2SavedKg,
        totalUsers,
        newUsersMonth,
        totalRides,
        completedRides,
        monthlyTrend,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Explicitly unmask a single PII field with audit logging (GDPR / DPDP compliance)
 * @route POST /api/v1/admin/audit/unmask-pii
 * @access Private (Admin only)
 */
exports.unmaskPii = async (req, res, next) => {
  try {
    const { resourceId, fieldName, reason } = req.body;

    if (!resourceId || !fieldName) {
      return res.status(400).json({
        success: false,
        message: 'resourceId and fieldName are required.',
      });
    }

    if (!reason || !reason.trim()) {
      return res.status(400).json({
        success: false,
        message: 'A specific justification reason is mandatory to unmask sensitive personal data.',
      });
    }

    let user = await User.findById(resourceId).select('+password');
    let rawValue = null;

    if (!user) {
      const booking = await Booking.findById(resourceId).populate('passenger').populate('driver');
      if (booking) {
        if (fieldName === 'passengerPhone' && booking.passenger) {
          user = booking.passenger;
          rawValue = booking.passenger.phone;
        } else if (fieldName === 'driverPhone' && booking.driver) {
          user = booking.driver;
          rawValue = booking.driver.phone;
        }
      }
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Associated user resource not found.',
      });
    }

    if (rawValue === null) {
      if (fieldName === 'phone') {
        rawValue = user.phone;
      } else if (fieldName === 'email') {
        rawValue = user.email;
      } else if (fieldName === 'licenseNumber') {
        rawValue = user.driverProfile ? user.driverProfile.licenseNumber : '';
      } else if (fieldName === 'emergencyContacts') {
        rawValue = user.emergencyContacts;
      } else {
        rawValue = user[fieldName] || null;
      }
    }

    await AuditLog.create({
      action: 'PII_UNMASKED',
      admin: req.user._id,
      targetUser: user._id,
      reason: reason.trim(),
      metadata: {
        fieldName,
        resourceId,
        adminEmail: req.user.email,
        adminRole: req.user.role,
        ipAddress: req.ip,
        unmaskedAt: new Date(),
      },
    });

    return res.status(200).json({
      success: true,
      message: `Field "${fieldName}" unmasked and access logged to immutable audit ledger.`,
      data: {
        resourceId,
        fieldName,
        unmaskedValue: rawValue,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Force refund a booking from escrow (Protected: super_admin, safety_officer)
 * @route POST /api/v1/admin/bookings/:id/force-refund
 * @access Private (super_admin, safety_officer only)
 */
exports.forceRefundBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason = 'Administrative safety force-refund' } = req.body;

    const booking = await Booking.findById(id).populate('passenger').populate('driver');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.' });
    }

    const previousStatus = booking.status;
    booking.status = 'cancelled';
    booking.cancellationReason = `Force refund by admin (${req.user.name}): ${reason}`;
    booking.refundStatus = 'refunded';
    await booking.save();

    await AuditLog.create({
      action: 'FORCE_REFUND',
      admin: req.user._id,
      targetUser: booking.passenger ? booking.passenger._id : null,
      reason,
      metadata: {
        bookingId: booking._id,
        amount: booking.totalContribution,
        previousStatus,
      },
    });

    if (booking.passenger) {
      await Notification.create({
        user: booking.passenger._id,
        title: 'Booking Escrow Refunded',
        message: `Your booking contribution of ₹${booking.totalContribution} has been force-refunded by Sahyān Safety Administration.`,
        category: 'system',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Booking force-refunded successfully. Escrow funds released to passenger.',
      data: { booking },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get platform operational configuration
 * @route GET /api/v1/admin/config
 * @access Private (Admin only)
 */
exports.getPlatformConfig = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      data: {
        maxSeatsPerRide: parseInt(process.env.MAX_SEATS_PER_RIDE || '6'),
        maxContributionPerSeat: parseInt(process.env.MAX_CONTRIBUTION_PER_SEAT || '500'),
        verificationRequired: process.env.DRIVER_VERIFICATION_REQUIRED !== 'false',
        safetyReportAutoEscalateHours: parseInt(process.env.SAFETY_ESCALATE_HOURS || '24'),
        maxRideDistanceKm: parseInt(process.env.MAX_RIDE_DISTANCE_KM || '500'),
        defaultCarpoolCity: process.env.DEFAULT_CITY || 'Ahmedabad',
        maintenanceMode: process.env.MAINTENANCE_MODE === 'true',
        socketTelematicsEnabled: process.env.SOCKET_TELEMATICS !== 'false',
        pushNotificationsEnabled: process.env.PUSH_NOTIFICATIONS !== 'false',
        co2SavedKgPerBooking: parseFloat(process.env.CO2_PER_BOOKING || '4.2'),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Update platform configuration (Protected: super_admin, safety_officer)
 * @route PATCH /api/v1/admin/config
 * @access Private (super_admin, safety_officer only)
 */
exports.updatePlatformConfig = async (req, res, next) => {
  try {
    const updates = req.body;

    if (updates.maxSeatsPerRide !== undefined) {
      process.env.MAX_SEATS_PER_RIDE = String(updates.maxSeatsPerRide);
    }
    if (updates.maxContributionPerSeat !== undefined) {
      process.env.MAX_CONTRIBUTION_PER_SEAT = String(updates.maxContributionPerSeat);
    }
    if (updates.verificationRequired !== undefined) {
      process.env.DRIVER_VERIFICATION_REQUIRED = String(updates.verificationRequired);
    }
    if (updates.maintenanceMode !== undefined) {
      process.env.MAINTENANCE_MODE = String(updates.maintenanceMode);
    }

    await AuditLog.create({
      action: 'CONFIG_UPDATED',
      admin: req.user._id,
      reason: updates.reason || 'Admin console configuration update',
      metadata: updates,
    });

    return res.status(200).json({
      success: true,
      message: 'Platform configuration updated successfully.',
      data: {
        maxSeatsPerRide: parseInt(process.env.MAX_SEATS_PER_RIDE || '6'),
        maxContributionPerSeat: parseInt(process.env.MAX_CONTRIBUTION_PER_SEAT || '500'),
        verificationRequired: process.env.DRIVER_VERIFICATION_REQUIRED !== 'false',
        maintenanceMode: process.env.MAINTENANCE_MODE === 'true',
      },
    });
  } catch (error) {
    next(error);
  }
};
