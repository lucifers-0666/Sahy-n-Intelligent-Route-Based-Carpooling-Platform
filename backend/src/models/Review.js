const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: [true, 'Booking reference is required'],
      index: true,
    },
    ride: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ride',
      required: [true, 'Ride reference is required'],
      index: true,
    },
    reviewer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Reviewer reference is required'],
      index: true,
    },
    reviewee: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Reviewee reference is required'],
      index: true,
    },
    rating: {
      type: Number,
      required: [true, 'Rating is required'],
      min: [1, 'Rating cannot be less than 1'],
      max: [5, 'Rating cannot be greater than 5'],
    },
    tags: [
      {
        type: String,
        trim: true,
      },
    ],
    comment: {
      type: String,
      trim: true,
      maxlength: [500, 'Comment cannot exceed 500 characters'],
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Prevent duplicate reviews for the same booking by the same reviewer
reviewSchema.index({ booking: 1, reviewer: 1 }, { unique: true });
reviewSchema.index({ reviewee: 1, createdAt: -1 });

reviewSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) {
      ret.id = ret._id.toString();
    }
    return ret;
  },
});

module.exports = mongoose.model('Review', reviewSchema);
