const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    action: {
      type: String,
      required: true,
      enum: [
        'DRIVER_SUSPENDED',
        'DRIVER_BANNED',
        'DRIVER_REACTIVATED',
        'DRIVER_VERIFIED',
        'DRIVER_REJECTED',
        'DRIVER_APPLICATION_SUBMITTED',
        'RIDE_MODERATED',
        'RIDE_CANCELLED',
        'REPORT_RESOLVED',
        'REPORT_DISMISSED',
        'BOOKING_CANCELLED',
        'FORCE_REFUND',
        'USER_DELETED',
        'CONFIG_UPDATED',
        'ADMIN_LOGIN',
        'PII_UNMASKED',
        'POLICE_CALLED',
        'BOARDING_PIN_VERIFIED',
        'BOARDING_PIN_FAILED',
        'BOARDING_PIN_LOCKED',
        'CASH_PAYMENT_CONFIRMED',
        'UNPAID_CASH_REPORTED',
        'PAYMENT_ESCROW_HELD',
        'PAYMENT_VERIFICATION_REJECTED',
        'PAYMENT_REFUNDED',
        'PAYMENT_RECONCILED',
        'PAYMENT_DISPUTED',
        'DISPUTE_RESOLVED',
        'NO_SHOW_REPORTED',
        'WEBHOOK_PAYMENT_VERIFIED',
        'WEBHOOK_REJECTED',
        'FRAUD_RISK_TRIGGERED',
        'APPEAL_SUBMITTED',
        'APPEAL_RESOLVED',
        'TICKET_UPDATED',
        'TICKET_RESOLVED',
        'USER_ROLE_CHANGED',
      ],
      index: true,
    },
    admin: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    actorRole: {
      type: String,
      default: 'admin',
    },
    bookingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      default: null,
      index: true,
    },
    rideId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ride',
      default: null,
      index: true,
    },
    targetUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    reason: {
      type: String,
      default: '',
      trim: true,
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

module.exports = mongoose.model('AuditLog', auditLogSchema);
