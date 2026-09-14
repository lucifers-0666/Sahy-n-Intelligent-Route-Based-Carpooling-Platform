const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: [true, 'Booking reference is required'],
      index: true,
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Sender is required'],
      index: true,
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Receiver is required'],
      index: true,
    },
    text: {
      type: String,
      required: [true, 'Message text is required'],
      trim: true,
      maxlength: [1000, 'Message cannot exceed 1000 characters'],
    },
    readAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for conversation querying and unread badge retrieval
messageSchema.index({ booking: 1, createdAt: 1 });
messageSchema.index({ receiver: 1, readAt: 1 });

messageSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) {
      ret.id = ret._id.toString();
    }
    return ret;
  },
});

module.exports = mongoose.model('Message', messageSchema);
