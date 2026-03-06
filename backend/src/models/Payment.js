const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');
const Customer = require('./Customer');
const Sale = require('./Sale');

const Payment = sequelize.define('Payment', {
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
    },
    customer_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Customer, key: 'id' },
    },
    sale_id: {
        type: DataTypes.INTEGER,
        allowNull: true, // If paying for a specific invoice
        references: { model: Sale, key: 'id' },
    },
    amount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
    payment_date: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
    },
    payment_method: {
        type: DataTypes.ENUM('cash', 'card', 'mobile'),
        defaultValue: 'cash',
    },
}, {
    tableName: 'payments',
    timestamps: true,
    underscored: true,
});

Customer.hasMany(Payment, { foreignKey: 'customer_id' });
Payment.belongsTo(Customer, { foreignKey: 'customer_id' });

module.exports = Payment;
