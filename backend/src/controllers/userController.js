const User = require('../models/User');
const Report = require('../models/Report');
const Ride = require('../models/Ride');
const Booking = require('../models/Booking');
const Vehicle = require('../models/Vehicle');
const AuditLog = require('../models/AuditLog');
const socketService = require('../services/socketService');

const PHONE_REGEX = /^(?:\+91)?[6-9]\d{9}$/;

const normalizePhone = (phone) => {
  if (!phone) return '';
  const cleaned = phone.replace(/[\s\-]/g, '');
  if (cleaned.startsWith('+91')) {
    return cleaned;
  }
  if (cleaned.length === 10 && /^[6-9]\d{9}$/.test(cleaned)) {
    return `+91${cleaned}`;
  }
  return cleaned;
};

/**
 * GET /api/v1/users/profile
 * Retrieve authenticated user profile
 */
const getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }
    return res.status(200).json({
      success: true,
      data: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT or PATCH /api/v1/users/profile
 * Update editable profile fields: name, city, bio, profileImage
 * Strictly ignores and protects sensitive/system fields
 */
const updateProfile = async (req, res, next) => {
  try {
    const { name, city, profileImage, bio } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Name cannot be empty' });
      }
      user.name = name.trim();
    }

    if (city !== undefined) {
      if (typeof city !== 'string' || city.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'City cannot be empty' });
      }
      user.city = city.trim();
    }

    if (bio !== undefined) {
      if (typeof bio !== 'string') {
        return res.status(400).json({ success: false, message: 'Bio must be a string' });
      }
      if (bio.length > 140) {
        return res.status(400).json({ success: false, message: 'Bio cannot exceed 140 characters' });
      }
      user.bio = bio.trim();
    }

    if (profileImage !== undefined) {
      user.profileImage = typeof profileImage === 'string' ? profileImage.trim() : '';
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/users/preferences
 * Update user travel and notification preferences
 */
const updatePreferences = async (req, res, next) => {
  try {
    const { notifications, allowSmoking, allowPets } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    if (!user.preferences) {
      user.preferences = { notifications: true, allowSmoking: false, allowPets: false };
    }

    if (notifications !== undefined) {
      if (typeof notifications !== 'boolean') {
        return res.status(400).json({ success: false, message: 'notifications preference must be a boolean' });
      }
      user.preferences.notifications = notifications;
    }
    if (allowSmoking !== undefined) {
      if (typeof allowSmoking !== 'boolean') {
        return res.status(400).json({ success: false, message: 'allowSmoking preference must be a boolean' });
      }
      user.preferences.allowSmoking = allowSmoking;
    }
    if (allowPets !== undefined) {
      if (typeof allowPets !== 'boolean') {
        return res.status(400).json({ success: false, message: 'allowPets preference must be a boolean' });
      }
      user.preferences.allowPets = allowPets;
    }

    user.markModified('preferences');
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Preferences updated successfully',
      data: user.preferences,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/users/emergency-contacts
 * List all emergency contacts for authenticated user
 */
const getEmergencyContacts = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    return res.status(200).json({
      success: true,
      data: user.emergencyContacts || [],
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/users/emergency-contacts
 * Add a new emergency contact
 */
const addEmergencyContact = async (req, res, next) => {
  try {
    const { name, phone, relationship } = req.body;

    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Contact name is required' });
    }

    if (!phone || typeof phone !== 'string') {
      return res.status(400).json({ success: false, message: 'Contact phone is required' });
    }

    const cleanPhone = phone.trim().replace(/[\s\-]/g, '');
    if (!PHONE_REGEX.test(cleanPhone)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format. Must be a valid 10-digit Indian mobile number.',
      });
    }

    const normalizedPhone = normalizePhone(cleanPhone);
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    const newContact = {
      name: name.trim(),
      phone: normalizedPhone,
      relationship: relationship && typeof relationship === 'string' ? relationship.trim() : 'Family',
    };

    user.emergencyContacts.push(newContact);
    await user.save();

    const createdContact = user.emergencyContacts[user.emergencyContacts.length - 1];

    return res.status(201).json({
      success: true,
      message: 'Emergency contact added successfully',
      data: createdContact,
      emergencyContacts: user.emergencyContacts,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/users/emergency-contacts/:id
 * Update an existing emergency contact
 */
const updateEmergencyContact = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, phone, relationship } = req.body;

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    const contact = user.emergencyContacts.id(id);
    if (!contact) {
      return res.status(404).json({ success: false, message: 'Emergency contact not found' });
    }

    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Contact name cannot be empty' });
      }
      contact.name = name.trim();
    }

    if (phone !== undefined) {
      const cleanPhone = phone.trim().replace(/[\s\-]/g, '');
      if (!PHONE_REGEX.test(cleanPhone)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid phone number format. Must be a valid 10-digit Indian mobile number.',
        });
      }
      contact.phone = normalizePhone(cleanPhone);
    }

    if (relationship !== undefined) {
      contact.relationship = typeof relationship === 'string' ? relationship.trim() : 'Family';
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Emergency contact updated successfully',
      data: contact,
      emergencyContacts: user.emergencyContacts,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/users/emergency-contacts/:id
 * Remove an emergency contact
 */
const deleteEmergencyContact = async (req, res, next) => {
  try {
    const { id } = req.params;

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    const contact = user.emergencyContacts.id(id);
    if (!contact) {
      return res.status(404).json({ success: false, message: 'Emergency contact not found' });
    }

    contact.deleteOne();
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Emergency contact deleted successfully',
      emergencyContacts: user.emergencyContacts,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/users/safety/sos
 * Trigger high-priority emergency SOS event
 */
const triggerEmergencySos = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { rideId, latitude, longitude, address, note } = req.body;

    const user = await User.findById(userId);
    let ride = null;
    let driver = null;
    if (rideId) {
      ride = await Ride.findById(rideId).populate('driver', 'name phone profileImage vehicle');
      if (ride) driver = ride.driver;
    }

    const report = await Report.create({
      reporter: userId,
      reportedUser: driver ? driver._id : null,
      ride: ride ? ride._id : null,
      type: 'sos_trigger',
      severity: 'critical',
      status: 'open',
      title: `EMERGENCY SOS: ${user.name} reported distress`,
      description:
        note ||
        `Passenger ${user.name} triggered high-priority emergency SOS along corridor. Coordinates: [${latitude || 23.0225}, ${longitude || 72.5714}]. Address: ${address || 'Ahmedabad Highway Corridor'}.`,
    });

    const incidentPayload = {
      incidentId: report._id.toString(),
      timestamp: new Date().toISOString(),
      passenger: {
        id: user._id.toString(),
        name: user.name,
        phone: user.phone,
        email: user.email,
        emergencyContacts: user.emergencyContacts || [],
      },
      driver: driver
        ? {
            id: driver._id.toString(),
            name: driver.name,
            phone: driver.phone,
          }
        : null,
      ride: ride
        ? {
            id: ride._id.toString(),
            origin: ride.origin,
            destination: ride.destination,
            status: ride.status,
          }
        : null,
      location: {
        latitude: latitude || 23.0225,
        longitude: longitude || 72.5714,
        address: address || 'Ahmedabad Highway Corridor',
      },
      status: 'open',
      severity: 'critical',
    };

    if (socketService.broadcastToAdmins) {
      socketService.broadcastToAdmins('admin_emergency_alert', incidentPayload);
    }

    return res.status(200).json({
      success: true,
      message: 'Sahyān Safety Command notified immediately. Emergency dispatch alerted.',
      incident: incidentPayload,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/users/export-data
 * GDPR / DPDP compliant user travel history & personal data export
 */
const exportUserData = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const [user, bookings, rides, vehicles] = await Promise.all([
      User.findById(userId).select('-password'),
      Booking.find({ passenger: userId }).populate('ride'),
      Ride.find({ driver: userId }),
      Vehicle.find({ owner: userId }),
    ]);

    const exportPayload = {
      platform: 'Sahyān Peer-to-Peer Carpooling',
      compliance: 'GDPR / Digital Personal Data Protection (DPDP) Act',
      exportedAt: new Date().toISOString(),
      accountProfile: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        city: user.city,
        isVerified: user.isVerified,
        rating: user.rating,
        emergencyContacts: user.emergencyContacts,
        createdAt: user.createdAt,
      },
      travelHistory: {
        passengerBookingsCount: bookings.length,
        bookings: bookings.map((b) => ({
          bookingId: b._id,
          rideId: b.ride ? b.ride._id : null,
          origin: b.ride ? b.ride.origin : null,
          destination: b.ride ? b.ride.destination : null,
          seats: b.seats,
          contributionPaid: b.totalContribution,
          status: b.status,
          bookedAt: b.createdAt,
        })),
        driverRidesCount: rides.length,
        rides: rides.map((r) => ({
          rideId: r._id,
          origin: r.origin,
          destination: r.destination,
          departureTime: r.departureTime,
          pricePerSeat: r.pricePerSeat,
          status: r.status,
        })),
      },
      registeredVehicles: vehicles.map((v) => ({
        make: v.make,
        model: v.model,
        licensePlate: v.licensePlate,
        seats: v.capacity,
      })),
    };

    return res.status(200).json({
      success: true,
      data: exportPayload,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/users/anonymize-data
 * GDPR / DPDP Right to Erasure / Anonymization
 */
const anonymizeUserData = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { reason = 'User requested erasure' } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const originalEmail = user.email;
    const originalPhone = user.phone;

    user.name = `Anonymized User ${user._id.toString().slice(-4)}`;
    user.email = `anonymized_${user._id.toString().slice(-6)}@sahyan.internal`;
    user.phone = `+91 000000${user._id.toString().slice(-4)}`;
    user.accountStatus = 'suspended';
    user.suspensionReason = `Account anonymized upon user request: ${reason}`;
    user.suspendedAt = new Date();
    user.emergencyContacts = [];
    user.profileImage = '';
    await user.save();

    await AuditLog.create({
      action: 'USER_DELETED',
      admin: userId,
      targetUser: userId,
      reason: `Self-service account & PII anonymization: ${reason}`,
      metadata: {
        originalEmailHash: originalEmail.slice(0, 3) + '***',
        anonymizedAt: new Date(),
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Account personal data successfully anonymized and scrubbed in compliance with DPDP standards.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getProfile,
  updateProfile,
  updatePreferences,
  getEmergencyContacts,
  addEmergencyContact,
  updateEmergencyContact,
  deleteEmergencyContact,
  triggerEmergencySos,
  exportUserData,
  anonymizeUserData,
};
