const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/', authenticate, messageController.sendMessage);
router.get('/', authenticate, messageController.getConversations);
router.get('/:bookingId', authenticate, messageController.getMessagesByBooking);

module.exports = router;
