const Tenant = require('../models/Tenant');
const User = require('../models/User');

// @desc    Register a new tenant (Business)
// @route   POST /api/auth/register-tenant
// @access  Public
const registerTenant = async (req, res) => {
    const {
        business_name,
        owner_name,
        email,
        phone,
        address,
        subscription_plan,
        password
    } = req.body;

    try {
        // 1. Check if email already exists
        const userExists = await User.findOne({ where: { email } });
        if (userExists) {
            return res.status(400).json({ message: 'Email-kan hore ayaa loo isticmaalay' });
        }

        // 2. Create Tenant
        const tenant = await Tenant.create({
            business_name,
            owner_name,
            email,
            phone,
            address,
            subscription_plan,
            status: 'pending', // Validation required by IT Admin
            branch_limit: subscription_plan === 'premium' ? 10 : 1,
        });

        // 3. Create Default Main Branch
        const Branch = require('../models/Branch');
        const branch = await Branch.create({
            tenant_id: tenant.id,
            branch_name: 'Main Branch',
            location: address || 'Mogadishu',
            phone: phone
        });

        // 4. Create the first admin for this tenant
        await User.create({
            tenant_id: tenant.id,
            branch_id: branch.id, // Assign to the main branch
            full_name: owner_name,
            email: email,
            password: password,
            role: 'tenant_admin',
            status: 'active',
        });

        res.status(201).json({
            message: 'Ganacsigaaga si guul leh ayaa loo diiwaangeliyey. IT Admin-ka ayaa ku soo xidhiidhi doona si uu nidaamka kuugu hawlgeliyo.',
            tenant: {
                id: tenant.id,
                business_name: tenant.business_name,
                email: tenant.email,
                status: tenant.status
            }
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { registerTenant };
