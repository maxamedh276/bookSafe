const express = require('express');
const router = express.Router();
const { registerTenant } = require('../controllers/tenantController');
const { loginUser } = require('../controllers/authController');

// Public routes
router.post('/register-tenant', registerTenant);
router.post('/login', loginUser);

module.exports = router;
