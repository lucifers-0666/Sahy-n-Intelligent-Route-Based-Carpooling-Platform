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
      if (ret.passenger._id) {
        ret.passenger.id = ret.passenger._id.toString();
      } else if (typeof ret.passenger === 'object' && typeof ret.passenger.toString === 'function') {
        ret.passenger = ret.passenger.toString();
      }
    }
    if (ret.ride) {
      if (ret.ride._id) {
        ret.ride.id = ret.ride._id.toString();
      } else if (typeof ret.ride === 'object' && typeof ret.ride.toString === 'function') {
        ret.ride = ret.ride.toString();
      }
    }
    return ret;
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
