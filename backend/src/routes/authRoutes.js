const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate, verifyFirebaseTokenOnly } = require('../middleware/authMiddleware');

// Firebase-authenticated canonical endpoints
router.post('/firebase-sync', verifyFirebaseTokenOnly, authController.firebaseSync);
router.post('/link-provider', authenticate, authController.linkProvider);

// Canonical & legacy authentication endpoints
router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', authenticate, authController.getMe);
router.post('/send-otp', authController.sendOtp);
router.post('/verify-otp', authController.verifyOtp);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

module.exports = router;
