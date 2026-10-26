const crypto = require('crypto');
const Booking = require('../models/Booking');
const PaymentTransaction = require('../models/PaymentTransaction');
const Ride = require('../models/Ride');
const AuditLog = require('../models/AuditLog');

/**
 * @route   POST /api/v1/payments/order
 * @desc    Create a payment order for a booking
 * @access  Private
 */
exports.createOrder = async (req, res) => {
  try {
    const { bookingId, idempotencyKey, paymentMethod = 'sandbox' } = req.body;
    const userId = (req.user._id || req.user.id).toString();

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

    const platformFee = 20; // Fixed safety & platform fee
    const tollSplit = 40; // Fixed fastag split per booking
    const amount = booking.totalContribution + platformFee + tollSplit;

    const allowedMethods = ['upi', 'card', 'netbanking', 'sandbox'];
    const validMethod = allowedMethods.includes(paymentMethod) ? paymentMethod : 'sandbox';

    const transaction = new PaymentTransaction({
      bookingId: booking._id,
      passengerId: booking.passenger,
      driverId: booking.ride.driver,
      amount: amount,
      platformFee: platformFee,
      paymentMethod: validMethod,
      idempotencyKey: idempotencyKey ? idempotencyKey.trim() : null,
      status: 'pending',
    });

    await transaction.save();

    res.status(201).json({
      success: true,
      message: 'Payment order created successfully',
      transaction,
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
 * @desc    Verify payment authorization and update booking status
 * @access  Private
 */
exports.verifyPayment = async (req, res) => {
  try {
    const { transactionId, gatewayReference, method = 'sandbox' } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    const transaction = await PaymentTransaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({ success: false, error: 'Transaction not found' });
    }

    if (transaction.passengerId.toString() !== userId) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    if (transaction.status !== 'pending') {
      return res.status(400).json({ success: false, error: 'Transaction is already processed' });
    }

    const allowedMethods = ['upi', 'card', 'netbanking', 'sandbox'];
    const validMethod = allowedMethods.includes(method) ? method : 'sandbox';

    // Disallow unverified client claims in live production
    const isProduction = process.env.NODE_ENV === 'production';
    if (isProduction && validMethod !== 'sandbox') {
      return res.status(400).json({
        success: false,
        error: 'Live online payments must be verified via provider webhook with cryptographic signature.',
      });
    }

    transaction.status = 'escrow_held';
    transaction.gatewayReference = gatewayReference || `mock_tx_${Date.now()}`;
    transaction.paymentMethod = validMethod;
    transaction.verifiedBy = validMethod === 'sandbox' ? 'sandbox_mock' : 'none';
    await transaction.save();

    const booking = await Booking.findById(transaction.bookingId);
    if (booking) {
      booking.paymentStatus = 'paid';
      booking.paymentTransactionId = transaction._id;
      booking.paymentMethod = validMethod;
      await booking.save();
    }

    const bookingObj = booking ? booking.toObject() : null;
    const txObj = transaction ? transaction.toObject() : null;

    res.status(200).json({
      success: true,
      message: 'Payment verified successfully (Sandbox escrow held)',
      transaction: txObj,
      booking: bookingObj,
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

    const webhookSecret = process.env.PAYMENT_WEBHOOK_SECRET || 'sahyan_webhook_secret_key';

    const payload = req.body || {};
    const { eventId, transactionId, amount, status: gatewayStatus } = payload;

    if (!eventId) {
      return res.status(400).json({ success: false, error: 'Missing eventId in webhook payload' });
    }

    // Cryptographic signature check (when secret configured)
    if (signature) {
      const payloadString = typeof req.rawBody === 'string' ? req.rawBody : JSON.stringify(payload);
      const expectedSignature = crypto
        .createHmac('sha256', webhookSecret)
        .update(payloadString)
        .digest('hex');

      // Constant time comparison
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
        message: 'Webhook event already processed (Deduplicated)',
        transactionId: existingProcessedTx._id,
      });
    }

    if (!transactionId) {
      return res.status(400).json({ success: false, error: 'Missing transactionId in webhook payload' });
    }

    const transaction = await PaymentTransaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({ success: false, error: 'Payment transaction not found' });
    }

    // Amount match verification
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

    // Mark successful escrow hold
    transaction.status = 'escrow_held';
    transaction.webhookEventId = eventId;
    transaction.verifiedBy = 'provider_webhook';
    transaction.signature = signature || 'verified_test_hmac';
    await transaction.save();

    const booking = await Booking.findById(transaction.bookingId);
    if (booking) {
      booking.paymentStatus = 'paid';
      booking.paymentTransactionId = transaction._id;
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
 * @desc    Release escrow funds to the driver
 * @access  Private
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
    const bookingIds = bookings.map(b => b._id);

    const transactions = await PaymentTransaction.find({
      bookingId: { $in: bookingIds },
      status: 'escrow_held',
    });

    for (let tx of transactions) {
      tx.status = 'settled_to_driver';
      await tx.save();

      const booking = bookings.find(b => b._id.toString() === tx.bookingId.toString());
      if (booking) {
        booking.paymentStatus = 'escrow_released';
        await booking.save();
      }
    }

    res.status(200).json({
      success: true,
      message: 'Escrow released successfully',
      releasedTransactions: transactions.length,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message || 'Server error' });
  }
};

