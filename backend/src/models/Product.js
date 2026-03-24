const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');
const Branch = require('./Branch');

const Product = sequelize.define('Product', {
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
    sku: {
        type: DataTypes.STRING(50),
        allowNull: true, // Can be null but unique per tenant
    },
    price: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0.00,
    },
    stock: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0,
    },
    category: {
        type: DataTypes.STRING(50),
    },
    total_quantity: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
    },
}, {
    tableName: 'products',
    timestamps: true,
    underscored: true,
    indexes: [
        { fields: ['tenant_id', 'sku'], unique: true }, // SKU must be unique per tenant
        { fields: ['name'] }
    ]
});

Tenant.hasMany(Product, { foreignKey: 'tenant_id' });
Product.belongsTo(Tenant, { foreignKey: 'tenant_id' });

Branch.hasMany(Product, { foreignKey: 'branch_id' });
Product.belongsTo(Branch, { foreignKey: 'branch_id' });

module.exports = Product;
