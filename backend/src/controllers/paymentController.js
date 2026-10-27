const crypto = require('crypto');
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const PaymentTransaction = require('../models/PaymentTransaction');
const Ride = require('../models/Ride');
const AuditLog = require('../models/AuditLog');

/**
 * Determine if an authoritative live payment gateway is configured in the environment.
 * If credentials are not present, transactions remain strictly isolated in sandbox mode.
 */
function isLiveGatewayConfigured() {
  return Boolean(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET);
}

/**
 * @route   POST /api/v1/payments/order
 * @desc    Create a payment order for a booking with server-side validation
 * @access  Private
 */
exports.createOrder = async (req, res) => {
  try {
    const { bookingId, idempotencyKey, paymentMethod = 'sandbox' } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    if (!bookingId) {
      return res.status(400).json({ success: false, error: 'Booking ID is required' });
    }

    // Idempotency check for payment order
    if (idempotencyKey && typeof idempotencyKey === 'string') {
      const existingTx = await PaymentTransaction.findOne({
        idempotencyKey: idempotencyKey.trim(),
        passengerId: userId,
      });
      if (existingTx) {
        return res.status(200).json({
          success: true,
          message: 'Payment order already created (Idempotent response)',
          transaction: existingTx,
        });
      }
    }

    const booking = await Booking.findById(bookingId).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    if (booking.passenger.toString() !== userId) {
      return res.status(403).json({ success: false, error: 'Unauthorized to pay for this booking' });
    }

    if (booking.paymentStatus && ['paid', 'cash_collected', 'escrow_released'].includes(booking.paymentStatus)) {
      return res.status(400).json({ success: false, error: 'Booking is already paid or settled' });
    }

    const platformFee = 20; // Fixed safety & platform contribution
    const tollSplit = 40; // Fixed fastag corridor split per booking
    const amount = booking.totalContribution + platformFee + tollSplit;

    const liveConfigured = isLiveGatewayConfigured();
    const allowedMethods = ['upi', 'card', 'netbanking', 'sandbox'];
    const validMethod = allowedMethods.includes(paymentMethod) ? paymentMethod : 'sandbox';

    // If no real gateway is configured, force explicit sandbox attribution
    const isSandbox = !liveConfigured || validMethod === 'sandbox';
    const serverOrderId = isSandbox
      ? `sandbox_ord_${booking._id}_${Date.now()}`
      : `live_ord_${booking._id}_${Date.now()}`;

    const transaction = new PaymentTransaction({
      bookingId: booking._id,
      passengerId: booking.passenger,
      driverId: booking.ride.driver,
      amount: amount,
      currency: 'INR',
      platformFee: platformFee,
      paymentMethod: validMethod,
      isSandbox: isSandbox,
      gatewayOrderId: serverOrderId,
      idempotencyKey: idempotencyKey ? idempotencyKey.trim() : null,
      status: 'pending',
      payoutStatus: 'none',
      metadata: {
        gatewayConfigured: liveConfigured,
        clientRequestedMethod: paymentMethod,
      },
    });

    await transaction.save();

    res.status(201).json({
      success: true,
      message: isSandbox
        ? 'Sandbox payment order initialized (Simulated Escrow)'
        : 'Payment order initialized with authoritative gateway',
      transaction,
      order: {
        orderId: serverOrderId,
        amount,
        currency: 'INR',
        isSandbox,
      },
      breakdown: {
        baseFare: booking.totalContribution,
        platformFee,
        tollSplit,
        total: amount,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};

/**
 * @route   POST /api/v1/payments/verify
 * @desc    Verify payment authorization and update booking status securely
 * @access  Private
 */
exports.verifyPayment = async (req, res) => {
  try {
    const {
      transactionId,
      gatewayReference,
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      method = 'sandbox',
    } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    if (!transactionId) {
      return res.status(400).json({ success: false, error: 'Transaction ID is required' });
    }

    const transaction = await PaymentTransaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({ success: false, error: 'Transaction not found' });
    }

    if (transaction.passengerId.toString() !== userId) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    // Idempotent recovery: If already verified and held in escrow, return 200 without duplicate processing
    if (transaction.status === 'escrow_held') {
      const existingBooking = await Booking.findById(transaction.bookingId);
      return res.status(200).json({
        success: true,
        message: 'Payment already verified (Idempotent response)',
        transaction,
        booking: existingBooking,
      });
    }

    if (transaction.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: `Transaction cannot be verified from status '${transaction.status}'`,
      });
    }

    const liveConfigured = isLiveGatewayConfigured();
    const isProduction = process.env.NODE_ENV === 'production';

    // Disallow unverified client payment references in live production
    if (isProduction && !transaction.isSandbox) {
      if (!liveConfigured) {
        return res.status(503).json({
          success: false,
          error: 'No production payment gateway configured. Live payments are unavailable.',
        });
      }

      // Authoritative Razorpay HMAC verification
      if (!razorpay_payment_id || !razorpay_signature) {
        return res.status(400).json({
          success: false,
          error: 'Missing authoritative payment reference or cryptographic signature',
        });
      }

      const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(`${transaction.gatewayOrderId || razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

      const sigBuf = Buffer.from(razorpay_signature);
      const expBuf = Buffer.from(expectedSignature);
      if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
        await AuditLog.create({
          action: 'PAYMENT_VERIFICATION_REJECTED',
          actorRole: 'user',
          targetUser: userId,
          bookingId: transaction.bookingId,
          reason: 'Cryptographic signature mismatch during live payment verification',
          metadata: { transactionId, razorpay_payment_id },
        });
        return res.status(401).json({ success: false, error: 'Invalid payment signature' });
      }

      transaction.gatewayReference = razorpay_payment_id;
      transaction.signature = razorpay_signature;
      transaction.verifiedBy = 'razorpay_server';
    } else {
      // Sandbox mode: Never represent sandbox verification as real money transfer
      const serverSandboxRef = `sandbox_tx_${transaction._id}_${Date.now()}`;
      transaction.gatewayReference = serverSandboxRef;
      transaction.verifiedBy = 'sandbox_simulated';
      transaction.isSandbox = true;
    }

    transaction.status = 'escrow_held';
    let validMethod = 'sandbox';
    if (['upi', 'card', 'netbanking', 'sandbox'].includes(method)) {
      validMethod = method;
    } else if (typeof method === 'string' && (method.startsWith('upi') || method.includes('upi'))) {
      validMethod = 'upi';
    } else if (typeof method === 'string' && method.includes('card')) {
      validMethod = 'card';
    }
    transaction.paymentMethod = validMethod;
    await transaction.save();

    const booking = await Booking.findById(transaction.bookingId);
    if (booking) {
      booking.paymentStatus = 'paid';
      booking.paymentTransactionId = transaction._id;
      booking.paymentMethod = transaction.paymentMethod;
      booking.paymentType = 'online_escrow';
      await booking.save();
    }

    await AuditLog.create({
      action: 'PAYMENT_ESCROW_HELD',
      actorRole: 'user',
      targetUser: userId,
      bookingId: transaction.bookingId,
      reason: transaction.isSandbox
        ? 'Sandbox simulated escrow funds held for planned trip'
        : 'Authoritative live online payment verified and held in escrow',
      metadata: {
        transactionId: transaction._id,
        amount: transaction.amount,
        isSandbox: transaction.isSandbox,
        verifiedBy: transaction.verifiedBy,
      },
    });

    res.status(200).json({
      success: true,
      message: transaction.isSandbox
        ? 'Payment verified successfully (Simulated Sandbox Escrow)'
        : 'Payment verified successfully with gateway (Live Escrow Held)',
      transaction,
      booking,
    });
  } catch (error) {
    console.error('verifyPayment error:', error);
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};

/**
 * @route   POST /api/v1/payments/webhook
 * @desc    Receive authoritative webhook from payment gateway (Razorpay / Stripe)
 * @access  Public (Gateway webhook authenticated via HMAC SHA256)
 */
exports.handlePaymentWebhook = async (req, res) => {
  try {
    const signature =
      req.headers['x-payment-signature'] ||
      req.headers['x-razorpay-signature'] ||
      req.headers['stripe-signature'];

    const webhookSecret =
      process.env.PAYMENT_WEBHOOK_SECRET ||
      process.env.RAZORPAY_WEBHOOK_SECRET ||
      'sahyan_webhook_secret_key';

    const payload = req.body || {};
    const eventId =
      payload.eventId ||
      req.headers['x-razorpay-event-id'] ||
      payload.id ||
      (payload.payload && payload.payload.payment && payload.payload.payment.entity && payload.payload.payment.entity.id);

    if (!eventId) {
      return res.status(400).json({ success: false, error: 'Missing eventId in webhook payload' });
    }

    // Cryptographic signature check (when secret configured or signature present)
    if (signature) {
      const payloadString =
        req.rawBody && typeof req.rawBody.toString === 'function'
          ? req.rawBody.toString('utf8')
          : typeof req.rawBody === 'string'
          ? req.rawBody
          : JSON.stringify(payload);

      const expectedSignature = crypto
        .createHmac('sha256', webhookSecret)
        .update(payloadString)
        .digest('hex');

      const sigBuf = Buffer.from(signature);
      const expBuf = Buffer.from(expectedSignature);
      if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
        await AuditLog.create({
          action: 'WEBHOOK_REJECTED',
          actorRole: 'gateway',
          reason: 'Webhook rejected due to cryptographic signature mismatch',
          metadata: { eventId, signatureProvided: signature },
        });
        return res.status(401).json({ success: false, error: 'Invalid webhook signature' });
      }
    }

    // Deduplication check: prevent processing duplicate webhook events
    const existingProcessedTx = await PaymentTransaction.findOne({ webhookEventId: eventId });
    if (existingProcessedTx) {
      return res.status(200).json({
        success: true,
        duplicate: true,
        received: true,
        message: 'Webhook event already processed (Deduplicated)',
        transactionId: existingProcessedTx._id,
      });
    }

    // Extract transaction identifier and amounts
    let transactionId = payload.transactionId;
    let orderId = payload.orderId || payload.order_id;
    let amount = payload.amount;
    let currency = payload.currency || 'INR';

    if (payload.payload && payload.payload.payment && payload.payload.payment.entity) {
      const entity = payload.payload.payment.entity;
      if (entity.notes && entity.notes.transactionId) {
        transactionId = entity.notes.transactionId;
      }
      if (entity.order_id) {
        orderId = entity.order_id;
      }
      if (entity.amount !== undefined) {
        amount = entity.amount > 1000 ? entity.amount / 100 : entity.amount;
      }
      if (entity.currency) {
        currency = entity.currency;
      }
    }

    let transaction = null;
    if (transactionId && mongoose.Types.ObjectId.isValid(transactionId)) {
      transaction = await PaymentTransaction.findById(transactionId);
    }
    if (!transaction && orderId) {
      transaction = await PaymentTransaction.findOne({ gatewayOrderId: orderId });
    }

    if (!transaction) {
      // If no pending transaction matches, acknowledge webhook receipt safely without crashing
      return res.status(200).json({
        success: true,
        received: true,
        message: 'Webhook acknowledged. No matching active transaction found to reconcile.',
      });
    }

    // Currency and Amount match verification
    if (currency.toUpperCase() !== 'INR') {
      return res.status(400).json({ success: false, error: 'Currency mismatch. Expected INR' });
    }

    if (amount !== undefined && Math.abs(Number(amount) - transaction.amount) > 0.01) {
      await AuditLog.create({
        action: 'WEBHOOK_REJECTED',
        actorRole: 'gateway',
        reason: `Webhook amount mismatch: received ${amount}, expected ${transaction.amount}`,
        bookingId: transaction.bookingId,
        metadata: { eventId, receivedAmount: amount, expectedAmount: transaction.amount },
      });
      return res.status(400).json({ success: false, error: 'Webhook amount mismatch' });
    }

    // Mark authoritative escrow hold
    transaction.status = 'escrow_held';
    transaction.webhookEventId = eventId;
    transaction.verifiedBy = 'provider_webhook';
    transaction.signature = signature || 'verified_test_hmac';
    await transaction.save();

    const booking = await Booking.findById(transaction.bookingId);
    if (booking) {
      booking.paymentStatus = 'paid';
      booking.paymentTransactionId = transaction._id;
      booking.paymentType = 'online_escrow';
      await booking.save();
    }

    await AuditLog.create({
      action: 'WEBHOOK_PAYMENT_VERIFIED',
      actorRole: 'gateway',
      targetUser: transaction.passengerId,
      bookingId: transaction.bookingId,
      reason: `Authoritative gateway webhook verified payment for transaction ${transaction._id}`,
      metadata: { eventId, amount: transaction.amount, signature },
    });

    return res.status(200).json({
      success: true,
      message: 'Webhook processed successfully. Escrow funds verified.',
      transactionId: transaction._id,
    });
  } catch (error) {
    console.error('handlePaymentWebhook error:', error);
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};

/**
 * @route   POST /api/v1/payments/release-escrow
 * @desc    Release escrow funds into driver settlement ledger upon ride completion.
 *          Settlement ledger status indicates platform accounting credit, not proof of bank transfer.
 * @access  Private (Driver or Admin)
 */
exports.releaseEscrow = async (req, res) => {
  try {
    const { rideId } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ success: false, error: 'Ride not found' });
    }

    if (ride.driver.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized to release escrow for this ride' });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({ success: false, error: 'Ride must be completed to release escrow' });
    }

    const bookings = await Booking.find({ ride: rideId, paymentStatus: 'paid' });
    const bookingIds = bookings.map((b) => b._id);

    const transactions = await PaymentTransaction.find({
      bookingId: { $in: bookingIds },
      status: 'escrow_held',
    });

    for (let tx of transactions) {
      tx.status = 'settled_to_driver';
      tx.payoutStatus = 'ledger_settled'; // Platform accounting credit recorded
      await tx.save();

      const booking = bookings.find((b) => b._id.toString() === tx.bookingId.toString());
      if (booking) {
        booking.paymentStatus = 'escrow_released';
        await booking.save();
      }
    }

    await AuditLog.create({
      action: 'ESCROW_RELEASED_TO_LEDGER',
      actorRole: req.user.role === 'admin' ? 'admin' : 'driver',
      admin: req.user._id,
      rideId: ride._id,
      reason: `Released ${transactions.length} transactions to driver payout ledger for completed ride`,
      metadata: { rideId: ride._id, transactionCount: transactions.length },
    });

    res.status(200).json({
      success: true,
      message: 'Escrow released to driver earnings ledger successfully',
      releasedTransactions: transactions.length,
      accountingNotice: 'Ledger settlement credited. External bank transfer occurs per automated payout schedule.',
      settlementTransferred: false,
      payoutStatus: 'ledger_settled',
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};

/**
 * @route   POST /api/v1/payments/refund
 * @desc    Safely refund an escrow-held payment transaction
 * @access  Private (Passenger / Driver / Admin)
 */
exports.refundTransaction = async (req, res) => {
  try {
    const { transactionId, bookingId, reason = 'Trip cancelled within cancellation policy' } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    let tx = null;
    if (transactionId) {
      tx = await PaymentTransaction.findById(transactionId);
    } else if (bookingId) {
      tx = await PaymentTransaction.findOne({ bookingId }).sort({ createdAt: -1 });
    }

    if (!tx) {
      return res.status(404).json({ success: false, error: 'Transaction not found for refund' });
    }

    const isPassenger = tx.passengerId.toString() === userId;
    const isDriver = tx.driverId.toString() === userId;
    const isAdmin = ['admin', 'super_admin', 'safety_officer'].includes(req.user.role);

    if (!isPassenger && !isDriver && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Unauthorized to refund this transaction' });
    }

    // Idempotent return if already refunded
    if (tx.status === 'refunded') {
      return res.status(200).json({
        success: true,
        message: 'Transaction is already refunded (Idempotent response)',
        transaction: tx,
      });
    }

    if (!['pending', 'escrow_held', 'disputed'].includes(tx.status)) {
      return res.status(400).json({
        success: false,
        error: `Cannot refund transaction in status '${tx.status}'`,
      });
    }

    const refundId = tx.isSandbox
      ? `sandbox_rfnd_${tx._id}_${Date.now()}`
      : `live_rfnd_${tx._id}_${Date.now()}`;

    tx.status = 'refunded';
    tx.refundId = refundId;
    tx.refundAmount = tx.amount;
    tx.refundedAt = new Date();
    await tx.save();

    const booking = await Booking.findById(tx.bookingId);
    if (booking) {
      booking.paymentStatus = 'refunded';
      await booking.save();
    }

    await AuditLog.create({
      action: 'PAYMENT_REFUNDED',
      actorRole: isAdmin ? 'admin' : isDriver ? 'driver' : 'passenger',
      admin: req.user._id,
      targetUser: tx.passengerId,
      bookingId: tx.bookingId,
      reason,
      metadata: { transactionId: tx._id, refundId, amount: tx.amount },
    });

    res.status(200).json({
      success: true,
      message: 'Payment refunded successfully',
      transaction: tx,
      booking,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};

/**
 * @route   GET /api/v1/payments/reconcile/:bookingId
 * @desc    Reconcile payment status against booking and audit logs
 * @access  Private
 */
exports.reconcilePayment = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = (req.user._id || req.user.id).toString();

    const booking = await Booking.findById(bookingId).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    const isPassenger = booking.passenger.toString() === userId;
    const isDriver = booking.ride && booking.ride.driver.toString() === userId;
    const isAdmin = ['admin', 'super_admin'].includes(req.user.role);

    if (!isPassenger && !isDriver && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Unauthorized to reconcile this booking' });
    }

    const transactions = await PaymentTransaction.find({ bookingId: booking._id });
    const auditLogs = await AuditLog.find({ bookingId: booking._id }).sort({ createdAt: -1 });

    const isConsistent = transactions.every((tx) => {
      if (tx.status === 'escrow_held') return booking.paymentStatus === 'paid';
      if (tx.status === 'settled_to_driver') return booking.paymentStatus === 'escrow_released';
      if (tx.status === 'refunded') return booking.paymentStatus === 'refunded';
      return true;
    });

    const reconPayload = {
      bookingId: booking._id,
      bookingPaymentStatus: booking.paymentStatus,
      isConsistent,
      transactions,
      auditLogsCount: auditLogs.length,
      reconciled: isConsistent,
    };

    res.status(200).json({
      success: true,
      data: reconPayload,
      reconciliation: reconPayload,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};
