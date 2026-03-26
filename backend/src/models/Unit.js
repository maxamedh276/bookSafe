const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const Unit = sequelize.define('Unit', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    name: {
        type: DataTypes.STRING(50),
        allowNull: false,
        unique: true,
    },
    abbreviation: {
        type: DataTypes.STRING(10),
        allowNull: false,
    },
}, {
    tableName: 'units',
    timestamps: true,
    underscored: true,
});

module.exports = Unit;
