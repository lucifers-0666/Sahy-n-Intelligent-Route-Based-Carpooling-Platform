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

    const booking = await Booking.findById(bookingId).populate('ride');
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    if (booking.passenger.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized to pay for this booking' });
    }

    if (booking.paymentStatus !== 'pending') {
      return res.status(400).json({ error: 'Booking is already paid or processing' });
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
    res.status(500).json({ error: error.message || 'Server error' });
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

    const transaction = await PaymentTransaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    if (transaction.passengerId.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (transaction.status !== 'pending') {
      return res.status(400).json({ error: 'Transaction is already processed' });
    }

    // In a real app, verify the signature with the payment gateway here.
    
    transaction.status = 'escrow_held';
    transaction.gatewayReference = gatewayReference || `mock_tx_${Date.now()}`;
    transaction.paymentMethod = method;
    await transaction.save();

    const booking = await Booking.findById(transaction.bookingId);
    booking.paymentStatus = 'paid';
    booking.paymentTransactionId = transaction._id;
    await booking.save();

    res.status(200).json({
      message: 'Payment verified successfully',
      transaction,
      booking,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Server error' });
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

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ error: 'Ride not found' });
    }

    // Usually triggered by system or driver when completing ride.
    if (ride.driver.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized to release escrow for this ride' });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({ error: 'Ride must be completed to release escrow' });
    }

    // Find all escrowed transactions for this ride
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
      message: 'Escrow released successfully',
      releasedTransactions: transactions.length,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Server error' });
  }
};
