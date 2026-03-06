const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Sale = require('./Sale');
const Product = require('./Product');

const SaleItem = sequelize.define('SaleItem', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    sale_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Sale, key: 'id' },
    },
    product_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: Product, key: 'id' },
    },
    quantity: {
        type: DataTypes.INTEGER,
        allowNull: false,
    },
    price: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false, // Price at the time of sale
    },
    subtotal: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
    },
}, {
    tableName: 'sale_items',
    timestamps: false,
    underscored: true,
});

Sale.hasMany(SaleItem, { foreignKey: 'sale_id', as: 'items' });
SaleItem.belongsTo(Sale, { foreignKey: 'sale_id' });

Product.hasMany(SaleItem, { foreignKey: 'product_id' });
SaleItem.belongsTo(Product, { foreignKey: 'product_id' });

module.exports = SaleItem;
