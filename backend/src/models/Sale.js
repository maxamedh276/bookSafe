const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');
const Branch = require('./Branch');
const User = require('./User');
const Customer = require('./Customer');

const Sale = sequelize.define('Sale', {
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
    user_id: {
        type: DataTypes.INTEGER, // The person who made the sale
        allowNull: false,
        references: { model: User, key: 'id' },
    },
    customer_id: {
        type: DataTypes.INTEGER,
        allowNull: true, // Can be guest customer
        references: { model: Customer, key: 'id' },
    },
    total_amount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
    paid_amount: {
        type: DataTypes.DECIMAL(10, 2),
        defaultValue: 0.00,
    },
    debt_amount: {
        type: DataTypes.DECIMAL(10, 2),
        defaultValue: 0.00,
    },
    payment_status: {
        type: DataTypes.ENUM('paid', 'credit'),
        allowNull: false,
    },
    invoice_number: {
        type: DataTypes.STRING(50),
        allowNull: false,
    },
    sale_date: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
    },
}, {
    tableName: 'sales',
    timestamps: true,
    underscored: true,
    indexes: [
        { fields: ['tenant_id', 'invoice_number'], unique: true },
        { fields: ['sale_date'] }
    ]
});

// Associations
Tenant.hasMany(Sale, { foreignKey: 'tenant_id' });
Sale.belongsTo(Tenant, { foreignKey: 'tenant_id' });

Customer.hasMany(Sale, { foreignKey: 'customer_id' });
Sale.belongsTo(Customer, { foreignKey: 'customer_id' });

module.exports = Sale;
