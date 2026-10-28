const express = require('express');
const router = express.Router();
const ticketController = require('../controllers/ticketController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/', authenticate, ticketController.createTicket);
router.get('/my', authenticate, ticketController.getMyTickets);
router.get('/:id', authenticate, ticketController.getTicketById);
router.post('/:id/reply', authenticate, ticketController.addTicketReply);
router.patch('/:id/resolve', authenticate, ticketController.resolveTicket);

module.exports = router;

