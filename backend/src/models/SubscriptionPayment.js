const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');

const SubscriptionPayment = sequelize.define('SubscriptionPayment', {
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
    plan: {
        type: DataTypes.STRING(50), // basic, premium
        allowNull: false,
    },
    amount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
    start_date: {
        type: DataTypes.DATEONLY,
    },
    end_date: {
        type: DataTypes.DATEONLY,
    },
    status: {
        type: DataTypes.ENUM('paid', 'pending', 'failed'),
        defaultValue: 'pending',
    },
}, {
    tableName: 'subscription_payments',
    timestamps: true,
    underscored: true,
});

Tenant.hasMany(SubscriptionPayment, { foreignKey: 'tenant_id' });
SubscriptionPayment.belongsTo(Tenant, { foreignKey: 'tenant_id' });

module.exports = SubscriptionPayment;
