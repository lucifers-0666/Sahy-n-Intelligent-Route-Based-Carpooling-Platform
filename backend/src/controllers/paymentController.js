const Booking = require('../models/Booking');
const PaymentTransaction = require('../models/PaymentTransaction');
const Ride = require('../models/Ride');

/**
 * @route   POST /api/v1/payments/order
 * @desc    Create a payment order for a booking
 * @access  Private
 */
exports.createOrder = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const userId = (req.user._id || req.user.id).toString();

    const booking = await Booking.findById(bookingId).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    if (booking.passenger.toString() !== userId) {
      return res.status(403).json({ success: false, error: 'Unauthorized to pay for this booking' });
    }

    if (booking.paymentStatus && booking.paymentStatus !== 'pending') {
      return res.status(400).json({ success: false, error: 'Booking is already paid or processing' });
    }

    const platformFee = 20; // Fixed safety & platform fee
    const tollSplit = 40; // Fixed fastag split per booking
    const amount = booking.totalContribution + platformFee + tollSplit;

    const transaction = new PaymentTransaction({
      bookingId: booking._id,
      passengerId: booking.passenger,
      driverId: booking.ride.driver,
      amount: amount,
      platformFee: platformFee,
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

    transaction.status = 'escrow_held';
    transaction.gatewayReference = gatewayReference || `mock_tx_${Date.now()}`;
    transaction.paymentMethod = validMethod;
    await transaction.save();

    const booking = await Booking.findById(transaction.bookingId);
    if (booking) {
      booking.paymentStatus = 'paid';
      booking.paymentTransactionId = transaction._id;
      await booking.save();
    }

    const bookingObj = booking ? booking.toObject() : null;
    const txObj = transaction ? transaction.toObject() : null;

    res.status(200).json({
      success: true,
      message: 'Payment verified successfully',
      transaction: txObj,
      booking: bookingObj,
    });
  } catch (error) {
    console.error('verifyPayment error:', error);
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

