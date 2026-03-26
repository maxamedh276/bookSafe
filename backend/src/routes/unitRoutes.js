const express = require('express');
const router = express.Router();
const { getUnits } = require('../controllers/unitController');
const { protect } = require('../middlewares/authMiddleware');

router.route('/').get(protect, getUnits);

module.exports = router;
