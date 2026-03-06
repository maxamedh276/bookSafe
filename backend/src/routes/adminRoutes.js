const express = require('express');
const router = express.Router();
const {
    getAllTenants,
    updateTenantStatus,
    getTenantDetails,
    impersonateTenant
} = require('../controllers/adminController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// All routes here are protected and restricted to IT Admin
router.use(protect);
router.use(authorize('it_admin'));

router.get('/tenants', getAllTenants);
router.get('/tenants/:id', getTenantDetails);
router.put('/tenants/:id/status', updateTenantStatus);
router.post('/tenants/:id/impersonate', impersonateTenant);

module.exports = router;
