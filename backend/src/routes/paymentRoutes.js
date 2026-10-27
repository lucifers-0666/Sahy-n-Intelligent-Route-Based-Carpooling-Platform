const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const { paymentLimiter } = require('../middleware/rateLimiter');
const {
  createOrder,
  verifyPayment,
  releaseEscrow,
  handlePaymentWebhook,
  refundTransaction,
  reconcilePayment,
} = require('../controllers/paymentController');

// Gateway Webhook route: Authenticated via cryptographic HMAC signature, not user JWT
router.post('/webhook', handlePaymentWebhook);

// User protected payment routes require authentication and rate limiting
router.post('/order', authenticate, paymentLimiter, createOrder);
router.post('/verify', authenticate, paymentLimiter, verifyPayment);
router.post('/release-escrow', authenticate, paymentLimiter, releaseEscrow);
router.post('/refund', authenticate, paymentLimiter, refundTransaction);
router.get('/reconcile/:bookingId', authenticate, reconcilePayment);

module.exports = router;
