const Branch = require('../models/Branch');
const Tenant = require('../models/Tenant');

// @desc    Get all branches for the logged-in user's tenant
// @route   GET /api/branches
// @access  Private (Tenant Admin, Branch Manager)
const getBranches = async (req, res) => {
    try {
        const query = { where: { tenant_id: req.user.tenant_id } };

        // If the user's role is branch_manager or cashier, they might only see their own branch
        if (req.user.role === 'branch_manager' || req.user.role === 'cashier') {
            query.where.id = req.user.branch_id;
        }

        const branches = await Branch.findAll(query);
        res.status(200).json(branches);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new branch
// @route   POST /api/branches
// @access  Private (Tenant Admin)
const createBranch = async (req, res) => {
    const { branch_name, location, phone } = req.body;

    try {
        // Prevent creating more branches than allowed
        const tenant = await Tenant.findByPk(req.user.tenant_id);
        const branchCount = await Branch.count({ where: { tenant_id: req.user.tenant_id } });

        if (branchCount >= tenant.branch_limit) {
            return res.status(403).json({ message: 'Waxaad gaartay xadka laamaha (branches). Fadlan u casriyeey qorshahaaga (upgrade plan).' });
        }

        const branch = await Branch.create({
            tenant_id: req.user.tenant_id,
            branch_name,
            location,
            phone
        });

        res.status(201).json({ message: 'Branch created successfully', branch });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update a branch
// @route   PUT /api/branches/:id
// @access  Private (Tenant Admin)
const updateBranch = async (req, res) => {
    const { branch_name, location, phone } = req.body;

    try {
        const branch = await Branch.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (!branch) {
            return res.status(404).json({ message: 'Branch not found' });
        }

        branch.branch_name = branch_name || branch.branch_name;
        branch.location = location || branch.location;
        branch.phone = phone || branch.phone;

        await branch.save();

        res.status(200).json({ message: 'Branch updated successfully', branch });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getBranches,
    createBranch,
    updateBranch
};
