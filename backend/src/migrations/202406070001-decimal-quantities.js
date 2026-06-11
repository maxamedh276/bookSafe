/** Support fractional units (e.g. 0.5 kg, 0.25 kg) in stock and sales. */
module.exports = {
    up: async (queryInterface, Sequelize) => {
        await queryInterface.changeColumn('products', 'stock', {
            type: Sequelize.DECIMAL(12, 3),
            allowNull: false,
            defaultValue: 0,
        });
        await queryInterface.changeColumn('products', 'total_quantity', {
            type: Sequelize.DECIMAL(12, 3),
            defaultValue: 0,
        });
        await queryInterface.changeColumn('sale_items', 'quantity', {
            type: Sequelize.DECIMAL(12, 3),
            allowNull: false,
        });
        await queryInterface.changeColumn('sales', 'total_quantity', {
            type: Sequelize.DECIMAL(12, 3),
            defaultValue: 0,
        });
    },
    down: async (queryInterface, Sequelize) => {
        await queryInterface.changeColumn('products', 'stock', {
            type: Sequelize.INTEGER,
            allowNull: false,
            defaultValue: 0,
        });
        await queryInterface.changeColumn('products', 'total_quantity', {
            type: Sequelize.INTEGER,
            defaultValue: 0,
        });
        await queryInterface.changeColumn('sale_items', 'quantity', {
            type: Sequelize.INTEGER,
            allowNull: false,
        });
        await queryInterface.changeColumn('sales', 'total_quantity', {
            type: Sequelize.INTEGER,
            defaultValue: 0,
        });
    },
};
