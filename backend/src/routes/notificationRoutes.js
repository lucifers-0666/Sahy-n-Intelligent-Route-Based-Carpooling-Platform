const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, notificationController.getNotifications);
router.patch('/read-all', authenticate, notificationController.markAllAsRead);
router.patch('/:id/read', authenticate, notificationController.markAsRead);
router.delete('/:id', authenticate, notificationController.deleteNotification);

module.exports = router;
