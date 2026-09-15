const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
  createOrder,
  verifyPayment,
  releaseEscrow,
} = require('../controllers/paymentController');

// All payment routes require authentication
router.use(protect);

router.post('/order', createOrder);
router.post('/verify', verifyPayment);
router.post('/release-escrow', releaseEscrow);

module.exports = router;
