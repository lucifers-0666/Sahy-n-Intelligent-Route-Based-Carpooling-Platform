const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const Ride = require('../models/Ride');

const ALLOWED_VEHICLE_TYPES = ['hatchback', 'sedan', 'suv', 'motorcycle', 'other'];

/**
 * @desc    Get all vehicles owned by the authenticated user
 * @route   GET /api/v1/vehicles
 * @access  Private (Authenticated User)
 */
const getVehicles = async (req, res, next) => {
  try {
    const vehicles = await Vehicle.find({ owner: req.user._id }).sort({ createdAt: -1 });
    return res.status(200).json({
      success: true,
      message: 'Vehicles retrieved successfully',
      data: {
        count: vehicles.length,
        vehicles,
      },
      count: vehicles.length,
      vehicles,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get single vehicle by ID
 * @route   GET /api/v1/vehicles/:id
 * @access  Private (Owner only)
 */
const getVehicleById = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle ID format.',
      });
    }

    const vehicle = await Vehicle.findById(id);

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

    return res.status(200).json({
      success: true,
      message: 'Vehicle retrieved successfully.',
      data: {
        vehicle,
      },
      vehicle,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Register a new vehicle & transition driver capability
 * @route   POST /api/v1/vehicles
 * @access  Private (Authenticated User)
 */
const createVehicle = async (req, res, next) => {
  try {
    const {
      registrationNumber,
      vehicleType,
      make,
      model,
      year,
      color,
      seatCapacity,
      vehicleImage,
    } = req.body;

    // Field presence validation
    if (!registrationNumber || !vehicleType || !make || !model || !year || !color || seatCapacity === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required vehicle fields: registrationNumber, vehicleType, make, model, year, color, seatCapacity.',
      });
    }

    // Vehicle Type Validation
    const normalizedType = String(vehicleType).trim().toLowerCase();
    if (!ALLOWED_VEHICLE_TYPES.includes(normalizedType)) {
      return res.status(400).json({
        success: false,
        message: `Invalid vehicle type '${vehicleType}'. Allowed types: ${ALLOWED_VEHICLE_TYPES.join(', ')}.`,
      });
    }

    // Year validation
    const parsedYear = Number(year);
    const currentYear = new Date().getFullYear();
    if (!Number.isInteger(parsedYear) || parsedYear < 1990 || parsedYear > currentYear + 1) {
      return res.status(400).json({
        success: false,
        message: `Manufacturing year must be an integer between 1990 and ${currentYear + 1}.`,
      });
    }

    // Seat Capacity validation
    const parsedCapacity = Number(seatCapacity);
    if (!Number.isInteger(parsedCapacity) || parsedCapacity < 1 || parsedCapacity > 8) {
      return res.status(400).json({
        success: false,
        message: 'Seat capacity must be an integer between 1 and 8.',
      });
    }

    // Registration number normalization and uniqueness check
    const normalizedReg = String(registrationNumber).replace(/\s+/g, '').toUpperCase();
    if (normalizedReg.length < 4 || normalizedReg.length > 15) {
      return res.status(400).json({
        success: false,
        message: 'Registration number must be between 4 and 15 alphanumeric characters.',
      });
    }

    const existingVehicle = await Vehicle.findOne({ registrationNumber: normalizedReg });
    if (existingVehicle) {
      return res.status(400).json({
        success: false,
        message: 'A vehicle with this registration number is already registered.',
      });
    }

    // Create Vehicle
    const vehicle = await Vehicle.create({
      owner: req.user._id,
      registrationNumber: normalizedReg,
      vehicleType: normalizedType,
      make: String(make).trim(),
      model: String(model).trim(),
      year: parsedYear,
      color: String(color).trim(),
      seatCapacity: parsedCapacity,
      vehicleImage: vehicleImage ? String(vehicleImage).trim() : '',
      status: 'active',
    });

    // Trusted Driver Capability Transition on User
    const user = await User.findById(req.user._id);
    if (user) {
      user.capabilities.canDrive = true;
      user.driverProfile.onboardingStatus = 'approved';
      if (!user.driverProfile.verifiedAt) {
        user.driverProfile.verifiedAt = new Date();
      }
      await user.save();
    }

    return res.status(201).json({
      success: true,
      message: 'Vehicle registered successfully.',
      data: {
        vehicle,
        user,
      },
      vehicle,
      user,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'A vehicle with this registration number is already registered.',
      });
    }
    next(error);
  }
};

/**
 * @desc    Update vehicle details
 * @route   PUT /api/v1/vehicles/:id
 * @access  Private (Owner only)
 */
const updateVehicle = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle ID format.',
      });
    }

    const vehicle = await Vehicle.findById(id);

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found.',
      });
    }

    if (vehicle.owner.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You do not have permission to modify this vehicle.',
      });
    }

    const {
      registrationNumber,
      vehicleType,
      make,
      model,
      year,
      color,
      seatCapacity,
      vehicleImage,
      status,
    } = req.body;

    if (registrationNumber !== undefined) {
      const normalizedReg = String(registrationNumber).replace(/\s+/g, '').toUpperCase();
      if (normalizedReg.length < 4 || normalizedReg.length > 15) {
        return res.status(400).json({
          success: false,
          message: 'Registration number must be between 4 and 15 alphanumeric characters.',
        });
      }

      if (normalizedReg !== vehicle.registrationNumber) {
        const existing = await Vehicle.findOne({ registrationNumber: normalizedReg });
        if (existing) {
          return res.status(400).json({
            success: false,
            message: 'A vehicle with this registration number is already registered.',
          });
        }
        vehicle.registrationNumber = normalizedReg;
      }
    }

    if (vehicleType !== undefined) {
      const normalizedType = String(vehicleType).trim().toLowerCase();
      if (!ALLOWED_VEHICLE_TYPES.includes(normalizedType)) {
        return res.status(400).json({
          success: false,
          message: `Invalid vehicle type '${vehicleType}'. Allowed types: ${ALLOWED_VEHICLE_TYPES.join(', ')}.`,
        });
      }
      vehicle.vehicleType = normalizedType;
    }

    if (make !== undefined) {
      const trimmedMake = String(make).trim();
      if (!trimmedMake) {
        return res.status(400).json({ success: false, message: 'Vehicle make cannot be empty.' });
      }
      vehicle.make = trimmedMake;
    }

    if (model !== undefined) {
      const trimmedModel = String(model).trim();
      if (!trimmedModel) {
        return res.status(400).json({ success: false, message: 'Vehicle model cannot be empty.' });
      }
      vehicle.model = trimmedModel;
    }

    if (year !== undefined) {
      const parsedYear = Number(year);
      const currentYear = new Date().getFullYear();
      if (!Number.isInteger(parsedYear) || parsedYear < 1990 || parsedYear > currentYear + 1) {
        return res.status(400).json({
          success: false,
          message: `Manufacturing year must be an integer between 1990 and ${currentYear + 1}.`,
        });
      }
      vehicle.year = parsedYear;
    }

    if (color !== undefined) {
      const trimmedColor = String(color).trim();
      if (!trimmedColor) {
        return res.status(400).json({ success: false, message: 'Vehicle color cannot be empty.' });
      }
      vehicle.color = trimmedColor;
    }

    if (seatCapacity !== undefined) {
      const parsedCapacity = Number(seatCapacity);
      if (!Number.isInteger(parsedCapacity) || parsedCapacity < 1 || parsedCapacity > 8) {
        return res.status(400).json({
          success: false,
          message: 'Seat capacity must be an integer between 1 and 8.',
        });
      }
      vehicle.seatCapacity = parsedCapacity;
    }

    if (vehicleImage !== undefined) {
      vehicle.vehicleImage = String(vehicleImage).trim();
    }

    if (status !== undefined) {
      const allowedStatuses = ['active', 'inactive', 'pending_verification', 'rejected'];
      if (!allowedStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: `Invalid vehicle status '${status}'.`,
        });
      }
      vehicle.status = status;
    }

    await vehicle.save();

    return res.status(200).json({
      success: true,
      message: 'Vehicle updated successfully.',
      data: {
        vehicle,
      },
      vehicle,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete vehicle
 * @route   DELETE /api/v1/vehicles/:id
 * @access  Private (Owner only)
 */
const deleteVehicle = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle ID format.',
      });
    }

    const vehicle = await Vehicle.findById(id);

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found.',
      });
    }

    if (vehicle.owner.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You do not have permission to delete this vehicle.',
      });
    }

    // Safety rule: Cannot delete a vehicle associated with active or scheduled rides
    const activeRide = await Ride.findOne({
      vehicle: id,
      status: { $in: ['scheduled', 'boarding', 'active'] },
    });
    if (activeRide) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete vehicle associated with an active or scheduled ride.',
      });
    }

    await Vehicle.findByIdAndDelete(id);

    // Check if user has any remaining vehicles
    const remainingCount = await Vehicle.countDocuments({ owner: req.user._id });
    const user = await User.findById(req.user._id);

    if (remainingCount === 0 && user) {
      user.capabilities.canDrive = false;
      user.driverProfile.onboardingStatus = 'not_started';
      await user.save();
    }

    return res.status(200).json({
      success: true,
      message: 'Vehicle deleted successfully.',
      data: {
        remainingVehicles: remainingCount,
        user,
      },
      remainingVehicles: remainingCount,
      user,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getVehicles,
  getVehicleById,
  createVehicle,
  updateVehicle,
  deleteVehicle,
};
