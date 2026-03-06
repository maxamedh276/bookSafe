const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const Tenant = require('./Tenant');
const User = require('./User');

const AuditLog = sequelize.define('AuditLog', {
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
    user_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: User, key: 'id' },
    },
    action: {
        type: DataTypes.STRING(50), // INSERT, UPDATE, DELETE
        allowNull: false,
    },
    table_name: {
        type: DataTypes.STRING(50),
        allowNull: false,
    },
    record_id: {
        type: DataTypes.INTEGER,
    },
    old_value: {
        type: DataTypes.JSON,
    },
    new_value: {
        type: DataTypes.JSON,
    },
}, {
    tableName: 'audit_logs',
    timestamps: true,
    updatedAt: false,
    underscored: true,
});

module.exports = AuditLog;
