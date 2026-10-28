const Ticket = require('../models/Ticket');
const Booking = require('../models/Booking');
const Ride = require('../models/Ride');
const AuditLog = require('../models/AuditLog');

const ALLOWED_ADMIN_ROLES = ['admin', 'super_admin', 'support_lead', 'safety_officer'];

// Create a new support ticket (User)
exports.createTicket = async (req, res) => {
  try {
    const { subject, description, category, priority, bookingId, rideId } = req.body;
    const userId = req.user._id;

    if (!subject || typeof subject !== 'string' || subject.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Valid ticket subject is required' });
    }

    if (!description || typeof description !== 'string' || description.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Valid ticket description is required' });
    }

    // Optional booking ownership verification
    let verifiedBookingId = null;
    let verifiedRideId = null;

    if (bookingId) {
      const booking = await Booking.findById(bookingId);
      if (booking) {
        if (booking.passenger.toString() === userId.toString() || booking.driver.toString() === userId.toString()) {
          verifiedBookingId = booking._id;
          verifiedRideId = booking.ride;
        }
      }
    }

    if (rideId && !verifiedRideId) {
      const ride = await Ride.findById(rideId);
      if (ride) {
        verifiedRideId = ride._id;
      }
    }

    let ticketNumber;
    let isUnique = false;
    let attempts = 0;
    while (!isUnique && attempts < 5) {
      ticketNumber = Ticket.generateTicketNumber();
      const existing = await Ticket.findOne({ ticketNumber });
      if (!existing) isUnique = true;
      attempts++;
    }

    const ticket = await Ticket.create({
      ticketNumber,
      user: userId,
      booking: verifiedBookingId,
      ride: verifiedRideId,
      category: category || 'other',
      priority: priority || 'medium',
      subject: subject.trim(),
      description: description.trim(),
      status: 'open',
      messages: [
        {
          sender: 'user',
          senderId: userId,
          senderName: req.user.name || 'Member',
          senderRole: req.user.role || 'user',
          message: description.trim(),
          createdAt: new Date(),
        },
      ],
    });

    return res.status(201).json({
      success: true,
      message: 'Support ticket submitted successfully',
      data: ticket,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to create support ticket',
    });
  }
};

// Get current user's tickets
exports.getMyTickets = async (req, res) => {
  try {
    const userId = req.user._id;
    const { status = 'all', page = 1, limit = 20 } = req.query;

    const query = { user: userId };
    if (status && status !== 'all') {
      query.status = status;
    }

    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    const skip = (pageNum - 1) * limitNum;

    const [tickets, total] = await Promise.all([
      Ticket.find(query)
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .populate('booking', 'status totalContribution pickup drop')
        .lean(),
      Ticket.countDocuments(query),
    ]);

    return res.status(200).json({
      success: true,
      data: tickets,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to retrieve support tickets',
    });
  }
};

// Get ticket details by ID (User or Admin)
exports.getTicketById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    const userRole = req.user.role || 'user';

    const ticket = await Ticket.findById(id)
      .populate('user', 'name email phone role isVerified rating')
      .populate('booking', 'status totalContribution pickup drop departureTime seats')
      .populate('ride', 'origin destination departureTime status');

    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Support ticket not found' });
    }

    const isOwner = ticket.user._id.toString() === userId.toString();
    const isAdmin = ALLOWED_ADMIN_ROLES.includes(userRole);

    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to view this ticket',
      });
    }

    return res.status(200).json({
      success: true,
      data: ticket,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch ticket details',
    });
  }
};

// Reply to ticket (User or Admin)
exports.addTicketReply = async (req, res) => {
  try {
    const { id } = req.params;
    const { message } = req.body;
    const userId = req.user._id;
    const userRole = req.user.role || 'user';

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Message text is required' });
    }

    const ticket = await Ticket.findById(id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Support ticket not found' });
    }

    const isOwner = ticket.user.toString() === userId.toString();
    const isAdmin = ALLOWED_ADMIN_ROLES.includes(userRole);

    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not authorized to reply to this ticket',
      });
    }

    if (ticket.status === 'closed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot reply to a closed ticket. Please submit a new ticket.',
      });
    }

    const senderType = isAdmin ? 'admin' : 'user';

    ticket.messages.push({
      sender: senderType,
      senderId: userId,
      senderName: req.user.name || (isAdmin ? 'Support Specialist' : 'Member'),
      senderRole: userRole,
      message: message.trim(),
      createdAt: new Date(),
    });

    // If an admin replies and ticket was open, mark in_progress
    if (isAdmin && ticket.status === 'open') {
      ticket.status = 'in_progress';
      ticket.assignedTo = userId;
    }

    await ticket.save();

    return res.status(200).json({
      success: true,
      message: 'Reply sent successfully',
      data: ticket,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to submit ticket reply',
    });
  }
};

// Mark ticket as resolved or closed
exports.resolveTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { status = 'resolved', resolutionNotes } = req.body;
    const userId = req.user._id;
    const userRole = req.user.role || 'user';

    if (!['resolved', 'closed'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status transition' });
    }

    const ticket = await Ticket.findById(id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Support ticket not found' });
    }

    const isOwner = ticket.user.toString() === userId.toString();
    const isAdmin = ALLOWED_ADMIN_ROLES.includes(userRole);

    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You cannot resolve this ticket',
      });
    }

    ticket.status = status;
    ticket.resolvedAt = new Date();
    if (resolutionNotes) {
      ticket.resolutionNotes = resolutionNotes.trim();
    }
    if (isAdmin) {
      ticket.assignedTo = userId;
    }

    await ticket.save();

    if (isAdmin) {
      await AuditLog.create({
        action: 'TICKET_RESOLVED',
        admin: userId,
        actorRole: userRole,
        targetUser: ticket.user,
        reason: `Support ticket ${ticket.ticketNumber} marked as ${status}: ${resolutionNotes || 'Resolved by support'}`,
      });
    }

    return res.status(200).json({
      success: true,
      message: `Support ticket successfully marked as ${status}`,
      data: ticket,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to update ticket status',
    });
  }
};

