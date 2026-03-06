const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const Tenant = sequelize.define('Tenant', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    business_name: {
        type: DataTypes.STRING(100),
        allowNull: false,
    },
    owner_name: {
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
    phone: {
        type: DataTypes.STRING(20),
        allowNull: false,
    },
    address: {
        type: DataTypes.TEXT,
    },
    subscription_plan: {
        type: DataTypes.ENUM('basic', 'premium'),
        defaultValue: 'basic',
    },
    status: {
        type: DataTypes.ENUM('pending', 'active', 'suspended', 'blocked'),
        defaultValue: 'pending',
    },
    branch_limit: {
        type: DataTypes.INTEGER,
        defaultValue: 1,
    },
    expiry_date: {
        type: DataTypes.DATEONLY,
    },
}, {
    tableName: 'tenants',
    timestamps: true,
    underscored: true,
});

module.exports = Tenant;
