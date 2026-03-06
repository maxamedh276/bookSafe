const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');
const Branch = require('./Branch');

const Customer = sequelize.define('Customer', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    tenant_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Tenant, key: 'id' },
    },
    branch_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Branch, key: 'id' },
    },
    name: {
        type: DataTypes.STRING(100),
        allowNull: false,
    },
    phone: {
        type: DataTypes.STRING(20),
        allowNull: false,
    },
    email: {
        type: DataTypes.STRING(100),
        validate: { isEmail: true },
    },
    address: {
        type: DataTypes.TEXT,
    },
    debt_balance: {
        type: DataTypes.DECIMAL(10, 2),
        defaultValue: 0.00,
    },
}, {
    tableName: 'customers',
    timestamps: true,
    underscored: true,
    indexes: [
        { fields: ['tenant_id', 'phone'] }, // Fast lookup by phone per business
        { fields: ['name'] }
    ]
});

Tenant.hasMany(Customer, { foreignKey: 'tenant_id' });
Customer.belongsTo(Tenant, { foreignKey: 'tenant_id' });

module.exports = Customer;
