const User = require('../models/User');
const bcrypt = require('bcryptjs');

// @desc    Get all users for the specific tenant
// @route   GET /api/users
// @access  Private (Tenant Admin)
const getUsers = async (req, res) => {
    try {
        const users = await User.findAll({
            where: { tenant_id: req.user.tenant_id },
            attributes: { exclude: ['password'] } // Do not return passwords
        });
        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new user (Branch Manager, Cashier, etc.)
// @route   POST /api/users
// @access  Private (Tenant Admin)
const createUser = async (req, res) => {
    const { full_name, email, password, role, branch_id } = req.body;

    try {
        // Only allow creation of specific roles
        if (!['tenant_admin', 'branch_manager', 'cashier'].includes(role)) {
            return res.status(400).json({ message: 'Doorka aan la oggolayn. Dooro "branch_manager" ama "cashier".' });
        }

        // Check if user exists
        const userExists = await User.findOne({ where: { email } });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Create user
        const user = await User.create({
            tenant_id: req.user.tenant_id,
            branch_id,
            full_name,
            email,
            password,
            role,
            status: 'active',
            created_by: req.user.id
        });

        res.status(201).json({
            message: 'User created successfully',
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                role: user.role,
                branch_id: user.branch_id
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update user
// @route   PUT /api/users/:id
// @access  Private (Tenant Admin)
const updateUser = async (req, res) => {
    const { full_name, role, status, branch_id } = req.body;

    try {
        const user = await User.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.full_name = full_name || user.full_name;
        user.role = role || user.role;
        user.status = status || user.status;
        user.branch_id = branch_id || user.branch_id;

        await user.save();

        res.status(200).json({
            message: 'User updated successfully',
            user: {
                id: user.id,
                full_name: user.full_name,
                role: user.role,
                status: user.status
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getUsers,
    createUser,
    updateUser
};
