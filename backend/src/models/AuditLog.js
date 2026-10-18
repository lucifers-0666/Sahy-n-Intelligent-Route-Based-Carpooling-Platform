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
      ],
      index: true,
    },
    admin: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
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
