const Review = require('../models/Review');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Notification = require('../models/Notification');
const mongoose = require('mongoose');

/**
 * POST /api/v1/reviews
 * Submit a rating and review for a completed or active carpool trip
 */
const createReview = async (req, res, next) => {
  try {
    const { bookingId, rating, tags, comment } = req.body;

    if (!bookingId || !mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({ success: false, message: 'Valid bookingId is required' });
    }

    const numRating = Number(rating);
    if (isNaN(numRating) || numRating < 1 || numRating > 5) {
      return res.status(400).json({ success: false, message: 'Rating must be a number between 1 and 5' });
    }

    const booking = await Booking.findById(bookingId).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const currentUserId = req.user._id.toString();
    const passengerId = (booking.passenger._id || booking.passenger).toString();
    const driverId = (booking.ride?.driver?._id || booking.ride?.driver).toString();

    const isPassenger = currentUserId === passengerId;
    const isDriver = currentUserId === driverId;

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You can only review trips you participated in',
      });
    }

    const revieweeId = isPassenger ? driverId : passengerId;
    if (currentUserId === revieweeId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot review yourself',
      });
    }

    // Check for duplicate review
    const existingReview = await Review.findOne({
      booking: booking._id,
      reviewer: req.user._id,
    });

    if (existingReview) {
      return res.status(409).json({
        success: false,
        message: 'You have already submitted a review for this booking',
      });
    }

    const cleanTags = Array.isArray(tags) ? tags.map((t) => String(t).trim()).filter(Boolean) : [];
    const cleanComment = typeof comment === 'string' ? comment.trim() : '';

    const review = await Review.create({
      booking: booking._id,
      ride: booking.ride._id,
      reviewer: req.user._id,
      reviewee: revieweeId,
      rating: Math.round(numRating),
      tags: cleanTags,
      comment: cleanComment,
    });

    // Recalculate reviewee average rating
    const allReviews = await Review.find({ reviewee: revieweeId });
    const totalRating = allReviews.reduce((sum, r) => sum + r.rating, 0);
    const newAverage = Number((totalRating / allReviews.length).toFixed(1));

    await User.findByIdAndUpdate(revieweeId, {
      'rating.average': newAverage,
      'rating.count': allReviews.length,
    });

    // Send notification to reviewee
    Notification.create({
      user: revieweeId,
      title: 'New Trip Review Received',
      message: `${req.user.name} rated your journey ${Math.round(numRating)} ★ "${cleanComment || (cleanTags[0] ?? 'Great ride')}"`,
      category: 'ride',
      routeTarget: '/reviews',
    }).catch((err) => console.error('[Notification] Error creating review notification:', err.message));

    const populatedReview = await Review.findById(review._id)
      .populate('reviewer', 'name profileImage')
      .populate('reviewee', 'name profileImage');

    return res.status(201).json({
      success: true,
      message: 'Review submitted successfully',
      data: populatedReview,
      driverRating: {
        average: newAverage,
        count: allReviews.length,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/reviews/user/:userId
 * Get public reviews received by a user
 */
const getUserReviews = async (req, res, next) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ success: false, message: 'Invalid userId parameter' });
    }

    const reviews = await Review.find({ reviewee: userId })
      .sort({ createdAt: -1 })
      .populate('reviewer', 'name profileImage');

    const user = await User.findById(userId).select('name rating');

    return res.status(200).json({
      success: true,
      data: {
        reviews,
        stats: {
          average: user?.rating?.average ?? 5.0,
          count: user?.rating?.count ?? reviews.length,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createReview,
  getUserReviews,
};
