const Notification = require('../models/Notification');
const mongoose = require('mongoose');

/**
 * GET /api/v1/notifications
 * Get in-app notifications for authenticated user
 */
const getNotifications = async (req, res, next) => {
  try {
    const { category } = req.query;
    const filter = { user: req.user._id };

    if (category && ['booking', 'ride', 'safety', 'system'].includes(category)) {
      filter.category = category;
    }

    const notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(50);
    const unreadCount = await Notification.countDocuments({ user: req.user._id, isRead: false });

    return res.status(200).json({
      success: true,
      data: {
        notifications,
        unreadCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/v1/notifications/:id/read
 * Mark a single notification as read
 */
const markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid notification id' });
    }

    const notification = await Notification.findOneAndUpdate(
      { _id: id, user: req.user._id },
      { $set: { isRead: true } },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    const unreadCount = await Notification.countDocuments({ user: req.user._id, isRead: false });

    return res.status(200).json({
      success: true,
      data: notification,
      unreadCount,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/v1/notifications/read-all
 * Mark all notifications as read for current user
 */
const markAllAsRead = async (req, res, next) => {
  try {
    const result = await Notification.updateMany(
      { user: req.user._id, isRead: false },
      { $set: { isRead: true } }
    );

    return res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
      modifiedCount: result.modifiedCount,
      unreadCount: 0,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/notifications/:id
 * Dismiss or delete a notification
 */
const deleteNotification = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid notification id' });
    }

    const deleted = await Notification.findOneAndDelete({ _id: id, user: req.user._id });
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    const unreadCount = await Notification.countDocuments({ user: req.user._id, isRead: false });

    return res.status(200).json({
      success: true,
      message: 'Notification dismissed',
      unreadCount,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
};
