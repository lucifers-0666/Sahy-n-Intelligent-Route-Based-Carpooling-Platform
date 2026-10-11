const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate } = require('../middleware/authMiddleware');

// Profile Endpoints
router.get('/profile', authenticate, userController.getProfile);
router.put('/profile', authenticate, userController.updateProfile);
router.patch('/profile', authenticate, userController.updateProfile);

// Preferences Endpoints
router.put('/preferences', authenticate, userController.updatePreferences);

// Emergency Contacts Endpoints
router.get('/emergency-contacts', authenticate, userController.getEmergencyContacts);
router.post('/emergency-contacts', authenticate, userController.addEmergencyContact);
router.put('/emergency-contacts/:id', authenticate, userController.updateEmergencyContact);
router.delete('/emergency-contacts/:id', authenticate, userController.deleteEmergencyContact);

// Real-Time Emergency SOS Endpoint
router.post('/safety/sos', authenticate, userController.triggerEmergencySos);

// GDPR / DPDP Privacy & Data Transparency Endpoints
router.get('/export-data', authenticate, userController.exportUserData);
router.post('/anonymize-data', authenticate, userController.anonymizeUserData);

module.exports = router;

