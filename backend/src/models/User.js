const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      unique: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [8, 'Password must be at least 8 characters'],
      validate: {
        validator: function (v) {
          return /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_\-+={}\[\]:;"'<>,.~`|\\])/.test(v);
        },
        message: 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
      },
      select: false,
    },
    profileImage: {
      type: String,
      default: '',
    },
    city: {
      type: String,
      default: 'Ahmedabad',
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },
    capabilities: {
      canRide: { type: Boolean, default: true },
      canDrive: { type: Boolean, default: false },
    },
    driverProfile: {
      onboardingStatus: {
        type: String,
        enum: ['not_started', 'in_progress', 'submitted', 'approved', 'rejected'],
        default: 'not_started',
      },
      licenseNumber: { type: String, default: '' },
      licenseDocUrl: { type: String, default: '' },
      rcDocUrl: { type: String, default: '' },
      idDocUrl: { type: String, default: '' },
      rejectionReason: { type: String, default: '' },
      verifiedAt: Date,
    },
    rating: {
      average: { type: Number, default: 4.9 },
      count: { type: Number, default: 0 },
    },
    bio: {
      type: String,
      maxlength: [140, 'Bio cannot exceed 140 characters'],
      default: '',
    },
    emergencyContacts: [
      {
        name: {
          type: String,
          required: [true, 'Contact name is required'],
          trim: true,
        },
        phone: {
          type: String,
          required: [true, 'Contact phone is required'],
          trim: true,
        },
        relationship: {
          type: String,
          default: 'Family',
          trim: true,
        },
      },
    ],
    preferences: {
      notifications: { type: Boolean, default: true },
      allowSmoking: { type: Boolean, default: false },
      allowPets: { type: Boolean, default: false },
    },
    otpInfo: {
      code: String,
      expiresAt: Date,
      attempts: { type: Number, default: 0 },
      verificationAttempts: { type: Number, default: 0 },
      lastRequestedAt: Date,
    },
    resetPasswordInfo: {
      token: String,
      expiresAt: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving if modified
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Instance method to compare candidate password
userSchema.methods.matchPassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Transform to remove sensitive fields when converting to JSON
userSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.password;
    delete ret.otpInfo;
    delete ret.resetPasswordInfo;
    delete ret.__v;
    ret.id = ret._id.toString();
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
