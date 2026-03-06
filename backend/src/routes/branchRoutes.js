const express = require('express');
const router = express.Router();
const {
    getBranches,
    createBranch,
    updateBranch
} = require('../controllers/branchController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);

router.route('/')
    .get(authorize('tenant_admin', 'branch_manager', 'cashier'), getBranches)
    .post(authorize('tenant_admin'), createBranch);

router.route('/:id')
    .put(authorize('tenant_admin'), updateBranch);

module.exports = router;
