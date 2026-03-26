const { Unit } = require('../models');

// @desc    Get all units
// @route   GET /api/units
// @access  Private
const getUnits = async (req, res) => {
    try {
        const units = await Unit.findAll({
            order: [['name', 'ASC']],
        });
        res.json(units);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getUnits,
};
