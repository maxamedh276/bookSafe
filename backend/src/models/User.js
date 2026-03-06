const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const bcrypt = require('bcryptjs');
const Tenant = require('./Tenant');
const Branch = require('./Branch');

const User = sequelize.define('User', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    tenant_id: {
        type: DataTypes.INTEGER,
        allowNull: true, // NULL for IT Admin
        references: {
            model: Tenant,
            key: 'id',
        },
    },
    branch_id: {
        type: DataTypes.INTEGER,
        allowNull: true, // NULL for IT Admin and Tenant Admin
        references: {
            model: Branch,
            key: 'id',
        },
    },
    full_name: {
        type: DataTypes.STRING(100),
        allowNull: false,
    },
    email: {
        type: DataTypes.STRING(100),
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true,
        },
    },
    password: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    role: {
        type: DataTypes.ENUM('it_admin', 'tenant_admin', 'branch_manager', 'cashier'),
        defaultValue: 'cashier',
    },
    status: {
        type: DataTypes.ENUM('active', 'blocked', 'pending'),
        defaultValue: 'active',
    },
    last_login: {
        type: DataTypes.DATE,
    },
}, {
    tableName: 'users',
    timestamps: true,
    underscored: true,
    hooks: {
        beforeCreate: async (user) => {
            if (user.password) {
                const salt = await bcrypt.genSalt(10);
                user.password = await bcrypt.hash(user.password, salt);
            }
        },
        beforeUpdate: async (user) => {
            if (user.changed('password')) {
                const salt = await bcrypt.genSalt(10);
                user.password = await bcrypt.hash(user.password, salt);
            }
        },
    },
});

// Associations
Tenant.hasMany(User, { foreignKey: 'tenant_id' });
User.belongsTo(Tenant, { foreignKey: 'tenant_id' });

Branch.hasMany(User, { foreignKey: 'branch_id' });
User.belongsTo(Branch, { foreignKey: 'branch_id' });

// Instance Method to validate password
User.prototype.matchPassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = User;
