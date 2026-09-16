const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createOrder,
  verifyPayment,
  releaseEscrow,
} = require('../controllers/paymentController');

// All payment routes require authentication
router.use(authenticate);

router.post('/order', createOrder);
router.post('/verify', verifyPayment);
router.post('/release-escrow', releaseEscrow);

module.exports = router;
