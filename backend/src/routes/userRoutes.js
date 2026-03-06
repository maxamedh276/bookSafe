const express = require('express');
const router = express.Router();
const {
    getUsers,
    createUser,
    updateUser
} = require('../controllers/userController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);

router.route('/')
    .get(authorize('tenant_admin'), getUsers)
    .post(authorize('tenant_admin'), createUser);

router.route('/:id')
    .put(authorize('tenant_admin'), updateUser);

module.exports = router;
