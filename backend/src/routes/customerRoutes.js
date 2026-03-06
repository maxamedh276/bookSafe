const express = require('express');
const router = express.Router();
const {
    getCustomers,
    createCustomer,
    getCustomerById,
    getDebtors,
    getCustomerHistory,
    updateCustomer,
    deleteCustomer
} = require('../controllers/customerController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/', getCustomers);
router.get('/debtors', getDebtors);
router.get('/:id', getCustomerById);
router.get('/:id/history', getCustomerHistory);
router.post('/', createCustomer);
router.put('/:id', authorize('tenant_admin', 'branch_manager'), updateCustomer);
router.delete('/:id', authorize('tenant_admin', 'branch_manager'), deleteCustomer);

module.exports = router;
