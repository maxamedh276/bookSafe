const express = require('express');
const router = express.Router();
const { recordPayment, getPayments } = require('../controllers/paymentController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/', getPayments);
router.post('/', recordPayment);

module.exports = router;
