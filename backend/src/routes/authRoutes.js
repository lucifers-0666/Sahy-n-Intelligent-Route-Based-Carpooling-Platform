const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate, verifyFirebaseTokenOnly } = require('../middleware/authMiddleware');
const { authLimiter, otpLimiter } = require('../middleware/rateLimiter');

// Firebase-authenticated canonical endpoints
router.post('/firebase-sync', verifyFirebaseTokenOnly, authController.firebaseSync);
router.post('/link-provider', authenticate, authController.linkProvider);

// Canonical & legacy authentication endpoints with rate limiting
router.post('/register', authLimiter, authController.register);
router.post('/login', authLimiter, authController.login);
router.get('/me', authenticate, authController.getMe);
router.post('/send-otp', otpLimiter, authController.sendOtp);
router.post('/verify-otp', authLimiter, authController.verifyOtp);
router.post('/forgot-password', authLimiter, authController.forgotPassword);
router.post('/reset-password', authLimiter, authController.resetPassword);
router.post('/appeal', authController.submitAppeal);
router.post('/logout', authController.logout);

module.exports = router;
