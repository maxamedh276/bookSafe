const Tenant = require('../models/Tenant');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// @desc    Get all tenants
// @route   GET /api/admin/tenants
// @access  Private/IT Admin
const getAllTenants = async (req, res) => {
    try {
        const tenants = await Tenant.findAll({
            order: [['created_at', 'DESC']]
        });
        res.json(tenants);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update tenant status (Approve, Block, etc.)
// @route   PUT /api/admin/tenants/:id/status
// @access  Private/IT Admin
const updateTenantStatus = async (req, res) => {
    const { status, expiry_date, branch_limit } = req.body;

    try {
        const tenant = await Tenant.findByPk(req.params.id);

        if (tenant) {
            tenant.status = status || tenant.status;
            tenant.expiry_date = expiry_date || tenant.expiry_date;
            tenant.branch_limit = branch_limit || tenant.branch_limit;

            const updatedTenant = await tenant.save();
            res.json(updatedTenant);
        } else {
            res.status(404).json({ message: 'Tenant-ka lama helin' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get tenant details with users and branches
// @route   GET /api/admin/tenants/:id
// @access  Private/IT Admin
const getTenantDetails = async (req, res) => {
    try {
        const tenant = await Tenant.findByPk(req.params.id, {
            include: [
                { model: User, attributes: ['id', 'full_name', 'email', 'role', 'status'] }
            ]
        });

        if (tenant) {
            res.json(tenant);
        } else {
            res.status(404).json({ message: 'Tenant-ka lama helin' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Impersonate a tenant
// @route   POST /api/admin/tenants/:id/impersonate
// @access  Private/IT Admin
const impersonateTenant = async (req, res) => {
    try {
        const tenant = await Tenant.findByPk(req.params.id);
        if (!tenant) {
            return res.status(404).json({ message: 'Tenant-ka lama helin' });
        }

        // Find the first admin of this tenant
        const user = await User.findOne({
            where: { tenant_id: tenant.id, role: 'tenant_admin' }
        });

        if (!user) {
            return res.status(404).json({ message: 'Admin-ka tenant-kan lama helin' });
        }

        // Generate token for this user
        const token = jwt.sign(
            { id: user.id, role: user.role, tenant_id: user.tenant_id, branch_id: user.branch_id },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                role: user.role,
                tenant_id: user.tenant_id,
                branch_id: user.branch_id,
                business_name: tenant.business_name
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getAllTenants,
    updateTenantStatus,
    getTenantDetails,
    impersonateTenant
};
