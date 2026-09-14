const Message = require('../models/Message');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const mongoose = require('mongoose');

/**
 * POST /api/v1/messages
 * Send a message within a specific booking context
 */
const sendMessage = async (req, res, next) => {
  try {
    const { bookingId, text, receiverId } = req.body;

    if (!bookingId || !mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({ success: false, message: 'Valid bookingId is required' });
    }

    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Message text is required' });
    }

    const booking = await Booking.findById(bookingId).populate('ride').populate('passenger');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const currentUserId = req.user._id.toString();
    const passengerId = (booking.passenger._id || booking.passenger).toString();
    const driverId = (booking.ride?.driver?._id || booking.ride?.driver).toString();

    // Verify user is a confirmed participant in this booking
    const isPassenger = currentUserId === passengerId;
    const isDriver = currentUserId === driverId;

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You are not a participant in this booking conversation',
      });
    }

    // Auto-resolve receiver if not provided or invalid
    let targetReceiverId = receiverId;
    if (!targetReceiverId) {
      targetReceiverId = isPassenger ? driverId : passengerId;
    }

    const message = await Message.create({
      booking: booking._id,
      sender: req.user._id,
      receiver: targetReceiverId,
      text: text.trim(),
    });

    const populated = await Message.findById(message._id)
      .populate('sender', 'name profileImage phone')
      .populate('receiver', 'name profileImage phone');

    // Create in-app notification for receiver asynchronously
    Notification.create({
      user: targetReceiverId,
      title: `New message from ${req.user.name}`,
      message: text.trim().length > 60 ? `${text.trim().substring(0, 57)}...` : text.trim(),
      category: 'booking',
      routeTarget: `/messages/${booking._id}`,
      routeParams: { bookingId: booking._id.toString() },
    }).catch((err) => console.error('[Notification] Error creating message notification:', err.message));

    return res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: populated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/messages/:bookingId
 * Retrieve message history for a specific booking
 */
const getMessagesByBooking = async (req, res, next) => {
  try {
    const { bookingId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({ success: false, message: 'Invalid bookingId parameter' });
    }

    const booking = await Booking.findById(bookingId).populate('ride');
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const currentUserId = req.user._id.toString();
    const passengerId = (booking.passenger._id || booking.passenger).toString();
    const driverId = (booking.ride?.driver?._id || booking.ride?.driver).toString();

    if (currentUserId !== passengerId && currentUserId !== driverId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You do not have access to this conversation',
      });
    }

    // Mark unread messages sent to the current user as read
    await Message.updateMany(
      {
        booking: booking._id,
        receiver: req.user._id,
        readAt: null,
      },
      {
        $set: { readAt: new Date() },
      }
    );

    const messages = await Message.find({ booking: booking._id })
      .sort({ createdAt: 1 })
      .populate('sender', 'name profileImage phone')
      .populate('receiver', 'name profileImage phone');

    return res.status(200).json({
      success: true,
      data: messages,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/messages
 * List all active conversations for current user
 */
const getConversations = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;

    // Find bookings where user is passenger
    const passengerBookings = await Booking.find({
      passenger: currentUserId,
      status: { $in: ['accepted', 'pending', 'completed'] },
    })
      .populate('ride')
      .populate({
        path: 'ride',
        populate: { path: 'driver', select: 'name profileImage phone' },
      });

    // Find rides where user is driver
    const driverBookings = await Booking.find({
      status: { $in: ['accepted', 'pending', 'completed'] },
    })
      .populate({
        path: 'ride',
        match: { driver: currentUserId },
      })
      .populate('passenger', 'name profileImage phone');

    const validDriverBookings = driverBookings.filter((b) => b.ride != null);
    const allBookings = [...passengerBookings, ...validDriverBookings];

    const conversations = await Promise.all(
      allBookings.map(async (booking) => {
        const isPassenger = booking.passenger._id
          ? booking.passenger._id.toString() === currentUserId.toString()
          : booking.passenger.toString() === currentUserId.toString();

        const partner = isPassenger ? booking.ride?.driver : booking.passenger;
        const lastMsg = await Message.findOne({ booking: booking._id }).sort({ createdAt: -1 });
        const unreadCount = await Message.countDocuments({
          booking: booking._id,
          receiver: currentUserId,
          readAt: null,
        });

        const routeSummary = booking.ride
          ? `${booking.ride.origin?.name || 'Origin'} to ${booking.ride.destination?.name || 'Destination'}`
          : `${booking.pickup?.name || 'Pickup'} to ${booking.drop?.name || 'Drop'}`;

        return {
          id: booking._id.toString(),
          bookingId: booking._id.toString(),
          participantName: partner?.name || (isPassenger ? 'Driver' : 'Passenger'),
          participantRole: isPassenger ? 'Driver' : 'Passenger',
          participantAvatar: partner?.profileImage || null,
          phone: partner?.phone || null,
          routeSummary,
          lastMessage: lastMsg ? lastMsg.text : 'Conversation initiated',
          lastMessageTime: lastMsg ? lastMsg.createdAt : booking.createdAt,
          unreadCount,
        };
      })
    );

    // Sort by most recent activity
    conversations.sort((a, b) => new Date(b.lastMessageTime) - new Date(a.lastMessageTime));

    return res.status(200).json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  sendMessage,
  getMessagesByBooking,
  getConversations,
};
