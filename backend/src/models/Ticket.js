const mongoose = require('mongoose');

const ticketMessageSchema = new mongoose.Schema({
  sender: {
    type: String,
    enum: ['user', 'admin'],
    required: true,
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  senderName: {
    type: String,
    required: true,
    trim: true,
  },
  senderRole: {
    type: String,
    default: 'user',
  },
  message: {
    type: String,
    required: [true, 'Message content is required'],
    trim: true,
    maxlength: [2000, 'Message cannot exceed 2000 characters'],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const ticketSchema = new mongoose.Schema(
  {
    ticketNumber: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
      uppercase: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      default: null,
      index: true,
    },
    ride: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ride',
      default: null,
      index: true,
    },
    category: {
      type: String,
      enum: [
        'ride_issue',
        'payment_inquiry',
        'driver_behavior',
        'technical_bug',
        'account_access',
        'other',
      ],
      default: 'other',
      index: true,
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'medium',
      index: true,
    },
    status: {
      type: String,
      enum: ['open', 'in_progress', 'resolved', 'closed'],
      default: 'open',
      index: true,
    },
    subject: {
      type: String,
      required: [true, 'Ticket subject is required'],
      trim: true,
      maxlength: [200, 'Subject cannot exceed 200 characters'],
    },
    description: {
      type: String,
      required: [true, 'Ticket description is required'],
      trim: true,
      maxlength: [2000, 'Description cannot exceed 2000 characters'],
    },
    messages: [ticketMessageSchema],
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    resolutionNotes: {
      type: String,
      default: null,
      maxlength: [2000, 'Resolution notes cannot exceed 2000 characters'],
    },
    resolvedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Helper static to generate formatted ticket identifier
ticketSchema.statics.generateTicketNumber = function () {
  const year = new Date().getFullYear();
  const randomPart = Math.floor(100000 + Math.random() * 900000);
  return `TKT-${year}-${randomPart}`;
};

module.exports = mongoose.model('Ticket', ticketSchema);

