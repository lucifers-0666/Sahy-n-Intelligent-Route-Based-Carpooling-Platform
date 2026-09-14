const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Notification title is required'],
      trim: true,
    },
    message: {
      type: String,
      required: [true, 'Notification message is required'],
      trim: true,
    },
    category: {
      type: String,
      enum: ['booking', 'ride', 'safety', 'system'],
      default: 'system',
      index: true,
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    routeTarget: {
      type: String,
      default: null,
    },
    routeParams: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ user: 1, isRead: 1 });

notificationSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) {
      ret.id = ret._id.toString();
    }
    return ret;
  },
});

module.exports = mongoose.model('Notification', notificationSchema);
