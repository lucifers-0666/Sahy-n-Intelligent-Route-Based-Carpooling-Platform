const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createOrder,
  verifyPayment,
  releaseEscrow,
  handlePaymentWebhook,
} = require('../controllers/paymentController');

// Gateway Webhook route: Authenticated via cryptographic HMAC signature, not user JWT
router.post('/webhook', handlePaymentWebhook);

// User protected payment routes require authentication
router.post('/order', authenticate, createOrder);
router.post('/verify', authenticate, verifyPayment);
router.post('/release-escrow', authenticate, releaseEscrow);

module.exports = router;
