const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude] in GeoJSON standard
      required: true,
      validate: {
        validator: function (coords) {
          if (!Array.isArray(coords) || coords.length !== 2) return false;
          const [lng, lat] = coords;
          return (
            typeof lng === 'number' &&
            typeof lat === 'number' &&
            lng >= -180 &&
            lng <= 180 &&
            lat >= -90 &&
            lat <= 90
          );
        },
        message: 'Coordinates must be [longitude, latitude] within valid geographic bounds.',
      },
    },
  },
  { _id: false }
);

const locationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Location name is required'],
      trim: true,
      maxlength: [200, 'Location name cannot exceed 200 characters'],
    },
    latitude: {
      type: Number,
      required: [true, 'Latitude is required'],
      min: [-90, 'Latitude must be between -90 and 90'],
      max: [90, 'Latitude must be between -90 and 90'],
    },
    longitude: {
      type: Number,
      required: [true, 'Longitude is required'],
      min: [-180, 'Longitude must be between -180 and 180'],
      max: [180, 'Longitude must be between -180 and 180'],
    },
    placeId: {
      type: String,
      trim: true,
      default: null,
    },
    point: {
      type: pointSchema,
      required: true,
    },
  },
  { _id: false }
);

const routeSchema = new mongoose.Schema(
  {
    encodedPolyline: {
      type: String,
      required: [true, 'Encoded polyline is required'],
      trim: true,
    },
    distanceMeters: {
      type: Number,
      required: [true, 'Distance in meters is required'],
      min: [50, 'Distance must be at least 50 meters'],
    },
    durationSeconds: {
      type: Number,
      required: [true, 'Duration in seconds is required'],
      min: [30, 'Duration must be at least 30 seconds'],
    },
  },
  { _id: false }
);

const rideSchema = new mongoose.Schema(
  {
    driver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Driver reference is required'],
      index: true,
    },
    vehicle: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Vehicle',
      required: [true, 'Vehicle reference is required'],
      index: true,
    },
    origin: {
      type: locationSchema,
      required: [true, 'Origin is required'],
    },
    destination: {
      type: locationSchema,
      required: [true, 'Destination is required'],
    },
    route: {
      type: routeSchema,
      required: [true, 'Route information is required'],
    },
    departureTime: {
      type: Date,
      required: [true, 'Departure time is required'],
      index: true,
    },
    estimatedArrivalTime: {
      type: Date,
      required: [true, 'Estimated arrival time is required'],
    },
    availableSeats: {
      type: Number,
      required: [true, 'Available seats count is required'],
      min: [1, 'At least 1 seat must be offered'],
      max: [8, 'Available seats cannot exceed 8'],
      validate: {
        validator: Number.isInteger,
        message: 'Available seats must be an integer',
      },
    },
    totalSeats: {
      type: Number,
      required: [true, 'Total seats count is required'],
      min: [1, 'Total seats must be at least 1'],
      max: [8, 'Total seats cannot exceed 8'],
      validate: {
        validator: Number.isInteger,
        message: 'Total seats must be an integer',
      },
    },
    bookedSeats: {
      type: Number,
      default: 0,
      min: [0, 'Booked seats cannot be negative'],
      validate: {
        validator: Number.isInteger,
        message: 'Booked seats must be an integer',
      },
    },
    contributionPerSeat: {
      type: Number,
      required: [true, 'Contribution per seat is required'],
      min: [0, 'Contribution per seat cannot be negative'],
    },
    pickupPolicy: {
      type: String,
      enum: {
        values: ['exact', 'nearby'],
        message: 'Pickup policy must be either exact or nearby',
      },
      default: 'nearby',
    },
    status: {
      type: String,
      enum: {
        values: ['scheduled', 'boarding', 'active', 'completed', 'cancelled'],
        message: 'Status must be scheduled, boarding, active, completed, or cancelled',
      },
      default: 'scheduled',
      index: true,
    },
    amenities: {
      type: [String],
      default: [],
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [500, 'Notes cannot exceed 500 characters'],
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Geospatial 2dsphere indexes for route origin and destination matching
rideSchema.index({ 'origin.point': '2dsphere' });
rideSchema.index({ 'destination.point': '2dsphere' });

// Compound indexes for queries
rideSchema.index({ driver: 1, status: 1 });
rideSchema.index({ status: 1, departureTime: 1 });

// Ensure JSON serialization formats id correctly
rideSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) {
      ret.id = ret._id.toString();
    }
    if (ret.driver) {
      if (ret.driver._id) {
        ret.driver.id = ret.driver._id.toString();
      } else if (typeof ret.driver === 'object' && typeof ret.driver.toString === 'function') {
        ret.driver = ret.driver.toString();
      }
    }
    if (ret.vehicle) {
      if (ret.vehicle._id) {
        ret.vehicle.id = ret.vehicle._id.toString();
      } else if (typeof ret.vehicle === 'object' && typeof ret.vehicle.toString === 'function') {
        ret.vehicle = ret.vehicle.toString();
      }
    }
    return ret;
  },
});

module.exports = mongoose.model('Ride', rideSchema);
