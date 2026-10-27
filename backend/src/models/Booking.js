const mongoose = require('mongoose');

const bookingLocationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
    point: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
  },
  { _id: false }
);

const bookingSchema = new mongoose.Schema(
  {
    passenger: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Passenger reference is required'],
      index: true,
    },
    ride: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ride',
      required: [true, 'Ride reference is required'],
      index: true,
    },
    requestedSeats: {
      type: Number,
      required: [true, 'Requested seats count is required'],
      min: [1, 'At least 1 seat must be requested'],
      max: [8, 'Cannot request more than 8 seats'],
      validate: {
        validator: Number.isInteger,
        message: 'Requested seats must be an integer',
      },
    },
    contributionPerSeat: {
      type: Number,
      required: [true, 'Contribution per seat snapshot is required'],
      min: [0, 'Contribution per seat cannot be negative'],
    },
    totalContribution: {
      type: Number,
      required: [true, 'Total contribution is required'],
      min: [0, 'Total contribution cannot be negative'],
    },
    status: {
      type: String,
      enum: {
        values: ['pending', 'accepted', 'rejected', 'cancelled', 'completed'],
        message: 'Status must be pending, accepted, rejected, cancelled, or completed',
      },
      default: 'pending',
      index: true,
    },
    // Boarding verification & PIN anti-tamper controls
    boardingPin: {
      type: String,
      default: null,
      trim: true,
    },
    boardingPinExpiresAt: {
      type: Date,
      default: null,
    },
    boardingPinAttempts: {
      type: Number,
      default: 0,
      min: 0,
    },
    boardingPinLocked: {
      type: Boolean,
      default: false,
    },
    boardedAt: {
      type: Date,
      default: null,
    },
    boardedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    // Payment method & state segregation
    paymentMethod: {
      type: String,
      enum: {
        values: ['cash', 'upi', 'card', 'netbanking', 'sandbox'],
        message: 'Payment method must be cash, upi, card, netbanking, or sandbox',
      },
      default: 'cash',
      index: true,
    },
    paymentType: {
      type: String,
      enum: {
        values: ['cash_on_boarding', 'online_escrow'],
        message: 'Payment type must be cash_on_boarding or online_escrow',
      },
      default: 'cash_on_boarding',
    },
    paymentStatus: {
      type: String,
      enum: {
        values: [
          'pending',
          'paid',
          'cash_collected',
          'unpaid_reported',
          'disputed',
          'escrow_released',
          'refunded',
        ],
        message: 'Payment status must be valid lifecycle state',
      },
      default: 'pending',
      index: true,
    },
    paymentTransactionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PaymentTransaction',
    },
    // Explicit terms & cancellation policy snapshot
    cancellationPolicy: {
      policyType: {
        type: String,
        enum: ['flexible', 'moderate', 'strict'],
        default: 'moderate',
      },
      description: {
        type: String,
        default: 'Free cancellation up to 2 hours before scheduled departure.',
      },
      acceptedAt: {
        type: Date,
        default: Date.now,
      },
    },
    // Non-payment & dispute management subdocument
    dispute: {
      status: {
        type: String,
        enum: [
          'none',
          'unpaid_reported',
          'passenger_disputed',
          'under_review',
          'refund_disputed',
          'no_show',
          'resolved_paid',
          'resolved_forgiven',
          'penalty_applied',
          'dismissed',
        ],
        default: 'none',
      },
      driverReportedAt: { type: Date, default: null },
      driverNotes: { type: String, default: '' },
      passengerRespondedAt: { type: Date, default: null },
      passengerNotes: { type: String, default: '' },
      evidenceUrls: [{ type: String }],
      resolvedAt: { type: Date, default: null },
      resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
      resolutionNotes: { type: String, default: '' },
    },
    idempotencyKey: {
      type: String,
      sparse: true,
      index: true,
      default: null,
    },
    passengerNote: {
      type: String,
      trim: true,
      maxlength: [500, 'Passenger note cannot exceed 500 characters'],
      default: '',
    },
    pickup: {
      type: bookingLocationSchema,
      required: [true, 'Pickup location snapshot is required'],
    },
    drop: {
      type: bookingLocationSchema,
      required: [true, 'Drop location snapshot is required'],
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for frequent queries
bookingSchema.index({ passenger: 1, createdAt: -1 });
bookingSchema.index({ ride: 1, status: 1 });

// Database-enforced partial unique index: only 1 active (pending or accepted) booking per passenger per ride
bookingSchema.index(
  { passenger: 1, ride: 1 },
  {
    unique: true,
    partialFilterExpression: { status: { $in: ['pending', 'accepted'] } },
  }
);

// Ensure JSON serialization formats id correctly
bookingSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) {
      ret.id = ret._id.toString();
    }
    if (ret.passenger) {
      if (ret.passenger instanceof mongoose.Types.ObjectId) {
        ret.passenger = ret.passenger.toString();
      } else if (typeof ret.passenger === 'object') {
        if (ret.passenger._id && !(ret.passenger._id instanceof mongoose.Types.ObjectId && ret.passenger._id === ret.passenger)) {
          ret.passenger.id = ret.passenger._id.toString();
        }
      }
    }
    if (ret.ride) {
      if (ret.ride instanceof mongoose.Types.ObjectId) {
        ret.ride = ret.ride.toString();
      } else if (typeof ret.ride === 'object') {
        if (ret.ride._id && !(ret.ride._id instanceof mongoose.Types.ObjectId && ret.ride._id === ret.ride)) {
          ret.ride.id = ret.ride._id.toString();
        }
      }
    }
    if (ret.paymentTransactionId && typeof ret.paymentTransactionId.toString === 'function') {
      ret.paymentTransactionId = ret.paymentTransactionId.toString();
    }
    return ret;
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
