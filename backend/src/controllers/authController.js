const User = require('../models/User');
const Tenant = require('../models/Tenant');
const generateToken = require('../utils/generateToken');

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
    const { email, password } = req.body;

    try {
        // 1. Find user by email
        const user = await User.findOne({
            where: { email },
            include: [{ model: Tenant, attributes: ['status', 'business_name', 'expiry_date'] }]
        });

        if (!user) {
            return res.status(401).json({ message: 'Email-ka ama Password-ka waa khalad' });
        }

        // 2. Check password
        const isMatch = await user.matchPassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Email-ka ama Password-ka waa khalad' });
        }

        // 3. Check Tenant status (Haddii aanu IT Admin ahayn)
        if (user.role !== 'it_admin' && user.Tenant) {
            const tenantStatus = user.Tenant.status;
            if (tenantStatus === 'pending') {
                return res.status(403).json({
                    message: 'Akoonkaaga wali waa PENDING. Fadlan sug inta IT Admin uu ku approve gareeyo.'
                });
            }
            if (tenantStatus === 'suspended') {
                return res.status(403).json({
                    message: 'Akoonkaaga waa la hakiyey (SUSPENDED). Fadlan la xidhiidh IT Admin-ka.'
                });
            }
            if (tenantStatus === 'blocked') {
                return res.status(403).json({
                    message: 'Akoonkaaga waa la xannibay (BLOCKED). Fadlan la xidhiidh IT Admin-ka.'
                });
            }
            if (tenantStatus !== 'active') {
                return res.status(403).json({
                    message: `Akoonkaaga xaaladdiisu waa "${tenantStatus}". Fadlan la xidhiidh IT Admin-ka.`
                });
            }
        }

        // 4. Update last login
        user.last_login = new Date();
        await user.save();

        res.json({
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            role: user.role,
            tenant_id: user.tenant_id,
            branch_id: user.branch_id,
            token: generateToken(user.id),
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { loginUser };
