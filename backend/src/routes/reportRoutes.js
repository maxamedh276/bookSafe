const express = require('express');
const router = express.Router();
const {
    getSalesSummary,
    getTopProducts,
    getTopDebtors,
    getDailySales,
    exportSalesCSV
} = require('../controllers/reportController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);
router.use(authorize('tenant_admin', 'branch_manager'));

router.get('/sales', getSalesSummary);
router.get('/top-products', getTopProducts);
router.get('/debtors', getTopDebtors);
router.get('/daily-sales', getDailySales);
router.get('/export-csv', exportSalesCSV);

module.exports = router;
