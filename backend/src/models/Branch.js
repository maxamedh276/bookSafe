const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');

const Branch = sequelize.define('Branch', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    tenant_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: Tenant,
            key: 'id',
        },
    },
    branch_name: {
        type: DataTypes.STRING(100),
        allowNull: false,
    },
    location: {
        type: DataTypes.STRING(255),
    },
    phone: {
        type: DataTypes.STRING(20),
    },
}, {
    tableName: 'branches',
    timestamps: true,
    underscored: true,
});

// Associations
Tenant.hasMany(Branch, { foreignKey: 'tenant_id' });
Branch.belongsTo(Tenant, { foreignKey: 'tenant_id' });

module.exports = Branch;
