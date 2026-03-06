const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    let token;

    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];

            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Get user from the token
            req.user = await User.findByPk(decoded.id, {
                attributes: { exclude: ['password'] }
            });

            if (!req.user) {
                return res.status(401).json({ message: 'Qofkan lama aqoonsan yahay (User not found)' });
            }

            next();
        } catch (error) {
            console.error(error);
            res.status(401).json({ message: 'Ma tihid qof la aqoonsan yahay' });
        }
    }

    if (!token) {
        res.status(401).json({ message: 'Fadlan soo dir token-ka (No token)' });
    }
};

// Role based access middleware
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                message: `Role-kaaga (${req.user.role}) uma oggola inuu galo qaybtan.`
            });
        }
        next();
    };
};

module.exports = { protect, authorize };
