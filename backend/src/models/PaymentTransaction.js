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
    currency: {
      type: String,
      default: 'INR',
      uppercase: true,
      trim: true,
    },
    platformFee: {
      type: Number,
      required: true,
      min: [0, 'Platform fee cannot be negative'],
    },
    paymentMethod: {
      type: String,
      enum: ['upi', 'card', 'netbanking', 'sandbox', 'upi_mock'],
      default: 'sandbox',
    },
    isSandbox: {
      type: Boolean,
      default: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'escrow_held', 'settled_to_driver', 'refunded', 'disputed', 'failed'],
      default: 'pending',
    },
    gatewayOrderId: {
      type: String,
      sparse: true,
      index: true,
    },
    gatewayReference: {
      type: String, // Authoritative payment ID from provider or sandbox audit ref
      sparse: true,
      index: true,
    },
    idempotencyKey: {
      type: String,
      sparse: true,
      unique: true,
      index: true,
    },
    webhookEventId: {
      type: String,
      sparse: true,
      unique: true,
      index: true,
    },
    signature: {
      type: String,
      default: null,
    },
    verifiedBy: {
      type: String,
      enum: [
        'provider_webhook',
        'razorpay_server',
        'stripe_server',
        'admin_override',
        'sandbox_mock',
        'sandbox_simulated',
        'none',
      ],
      default: 'none',
    },
    refundId: {
      type: String,
      default: null,
    },
    refundAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    refundedAt: {
      type: Date,
      default: null,
    },
    payoutStatus: {
      type: String,
      enum: ['none', 'ledger_settled', 'payout_pending', 'payout_transferred', 'payout_failed'],
      default: 'none',
    },
    payoutTransferredAt: {
      type: Date,
      default: null,
    },
    failureReason: {
      type: String,
      default: null,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

paymentTransactionSchema.index({ driverId: 1, status: 1 });
paymentTransactionSchema.index({ bookingId: 1, status: 1 });

paymentTransactionSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    if (ret._id) ret.id = ret._id.toString();
    if (ret.bookingId && typeof ret.bookingId.toString === 'function') ret.bookingId = ret.bookingId.toString();
    if (ret.passengerId && typeof ret.passengerId.toString === 'function') ret.passengerId = ret.passengerId.toString();
    if (ret.driverId && typeof ret.driverId.toString === 'function') ret.driverId = ret.driverId.toString();
    return ret;
  },
});

module.exports = mongoose.model('PaymentTransaction', paymentTransactionSchema);
