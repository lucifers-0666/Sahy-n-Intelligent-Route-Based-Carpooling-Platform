const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  getVehicles,
  getVehicleById,
  createVehicle,
  updateVehicle,
  deleteVehicle,
} = require('../controllers/vehicleController');

// All vehicle routes require authentication
router.use(authenticate);

router.route('/')
  .get(getVehicles)
  .post(createVehicle);

router.route('/:id')
  .get(getVehicleById)
  .put(updateVehicle)
  .patch(updateVehicle)
  .delete(deleteVehicle);

module.exports = router;
