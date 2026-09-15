const mongoose = require('mongoose');

const paymentTransactionSchema = new mongoose.Schema(
  {
    bookingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: true,
      index: true,
    },
    passengerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    driverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    amount: {
      type: Number,
      required: true,
      min: [0, 'Amount cannot be negative'],
    },
    platformFee: {
      type: Number,
      required: true,
      min: [0, 'Platform fee cannot be negative'],
    },
    paymentMethod: {
      type: String,
      enum: ['upi', 'card', 'netbanking', 'sandbox'],
      default: 'sandbox',
    },
    status: {
      type: String,
      enum: ['pending', 'escrow_held', 'settled_to_driver', 'refunded'],
      default: 'pending',
    },
    gatewayReference: {
      type: String, // Mock transaction ID in sandbox mode
    },
  },
  {
    timestamps: true,
  }
);

paymentTransactionSchema.index({ driverId: 1, status: 1 });

paymentTransactionSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) {
      ret.id = ret._id.toString();
    }
    return ret;
  },
});

module.exports = mongoose.model('PaymentTransaction', paymentTransactionSchema);
