const express = require('express');
const router = express.Router();
const {
    getProducts,
    createProduct,
    updateProduct,
    deleteProduct
} = require('../controllers/productController');
const { protect, authorize } = require('../middlewares/authMiddleware');
const { auditLog } = require('../middlewares/auditMiddleware');

router.use(protect);

router.get('/', getProducts);
router.post('/', authorize('tenant_admin', 'branch_manager', 'cashier'), auditLog('products'), createProduct);
router.put('/:id', authorize('tenant_admin', 'branch_manager'), auditLog('products'), updateProduct);
router.delete('/:id', authorize('tenant_admin', 'branch_manager'), auditLog('products'), deleteProduct);

module.exports = router;
