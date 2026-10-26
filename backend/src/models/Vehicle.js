const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Owner ID is required'],
      index: true,
    },
    registrationNumber: {
      type: String,
      required: [true, 'Registration number is required'],
      unique: true,
      trim: true,
      uppercase: true,
    },
    vehicleType: {
      type: String,
      required: [true, 'Vehicle type is required'],
      enum: {
        values: ['hatchback', 'sedan', 'suv', 'motorcycle', 'other'],
        message: 'Vehicle type must be hatchback, sedan, suv, motorcycle, or other',
      },
      lowercase: true,
      trim: true,
    },
    make: {
      type: String,
      required: [true, 'Vehicle make is required'],
      trim: true,
      maxlength: [50, 'Make cannot exceed 50 characters'],
    },
    model: {
      type: String,
      required: [true, 'Vehicle model is required'],
      trim: true,
      maxlength: [50, 'Model cannot exceed 50 characters'],
    },
    year: {
      type: Number,
      required: [true, 'Manufacturing year is required'],
      min: [1990, 'Year must be 1990 or later'],
      max: [new Date().getFullYear() + 1, 'Year cannot be in the future'],
    },
    color: {
      type: String,
      required: [true, 'Vehicle color is required'],
      trim: true,
      maxlength: [30, 'Color cannot exceed 30 characters'],
    },
    seatCapacity: {
      type: Number,
      required: [true, 'Seat capacity is required'],
      min: [1, 'Seat capacity must be at least 1'],
      max: [8, 'Seat capacity cannot exceed 8'],
      validate: {
        validator: Number.isInteger,
        message: 'Seat capacity must be an integer',
      },
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'pending_verification', 'rejected'],
      default: 'active',
    },
    rcExpiryDate: {
      type: Date,
      default: null,
    },
    insuranceExpiryDate: {
      type: Date,
      default: null,
    },
    pollutionCertExpiryDate: {
      type: Date,
      default: null,
    },
    vehicleImage: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Normalize registration number before saving (strip excess spaces, uppercase)
vehicleSchema.pre('save', function (next) {
  if (this.registrationNumber) {
    this.registrationNumber = this.registrationNumber.replace(/\s+/g, '').toUpperCase();
  }
  next();
});

// Remove sensitive internal fields on JSON conversion
vehicleSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    ret.id = ret._id.toString();
    if (ret.owner) {
      ret.owner = ret.owner.toString();
    }
    return ret;
  },
});

module.exports = mongoose.model('Vehicle', vehicleSchema);
