const User = require('../models/User');
const bcrypt = require('bcryptjs');
const Branch = require('../models/Branch'); // needed for branch validation
const { ValidationError } = require('sequelize');

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
        if (!full_name || !email || !password || !role) {
            return res.status(400).json({ message: 'Fadlan buuxi full_name, email, password, iyo role.' });
        }

        // Allowed roles only
        if (!['tenant_admin', 'branch_manager', 'cashier'].includes(role)) {
            return res.status(400).json({ message: 'Doorka aan la oggolayn. Dooro "branch_manager" ama "cashier".' });
        }

        // If role is branch_manager, a valid branch_id is required
        if (role === 'branch_manager') {
            if (!branch_id) {
                return res.status(400).json({ message: 'Branch ID waa in la siiyaa marka la abuuro Branch Manager.' });
            }
            const branch = await Branch.findOne({ where: { id: branch_id, tenant_id: req.user.tenant_id } });
            if (!branch) {
                return res.status(400).json({ message: 'Branch-ka la bixiyay ma jiro ama waxaa ka baxsan tenant-kaaga.' });
            }
        }

        // Check if user already exists
        const userExists = await User.findOne({ where: { email } });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Create the user (branch_id only stored for branch_manager, null otherwise)
        const user = await User.create({
            tenant_id: req.user.tenant_id,
            branch_id: role === 'branch_manager' ? branch_id : null,
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
        console.error('❌ createUser error:', error);
        if (error instanceof ValidationError) {
            return res.status(400).json({ message: error.errors?.[0]?.message || 'User validation failed.' });
        }
        res.status(500).json({ message: 'Server error while creating user.' });
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

        if (role && !['tenant_admin', 'branch_manager', 'cashier'].includes(role)) {
            return res.status(400).json({ message: 'Doorka aan la oggolayn.' });
        }

        if (role === 'branch_manager') {
            if (!branch_id) {
                return res.status(400).json({ message: 'Branch ID waa in la siiyaa marka user-ku yahay branch_manager.' });
            }
            const branch = await Branch.findOne({ where: { id: branch_id, tenant_id: req.user.tenant_id } });
            if (!branch) {
                return res.status(400).json({ message: 'Branch-ka la bixiyay ma jiro ama tenant-kan kama tirsana.' });
            }
        }

        user.full_name = full_name || user.full_name;
        user.role = role || user.role;
        user.status = status || user.status;
        user.branch_id = role === 'branch_manager' ? branch_id : (role ? null : user.branch_id);

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
        if (error instanceof ValidationError) {
            return res.status(400).json({ message: error.errors?.[0]?.message || 'User validation failed.' });
        }
        res.status(500).json({ message: 'Server error while updating user.' });
    }
};

module.exports = {
    getUsers,
    createUser,
    updateUser
};
