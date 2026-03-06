const express = require('express');
const router = express.Router();
const { createSale, getSales } = require('../controllers/saleController');
const { protect } = require('../middlewares/authMiddleware');
const { auditLog } = require('../middlewares/auditMiddleware');

router.use(protect);

router.get('/', getSales);
router.post('/', auditLog('sales'), createSale);

module.exports = router;
