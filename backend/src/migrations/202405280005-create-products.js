module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('products', {
      id: { type: Sequelize.INTEGER, primaryKey: true, autoIncrement: true },
      tenant_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'tenants', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      branch_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'branches', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      unit_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: { model: 'units', key: 'id' },
        onUpdate: 'SET NULL',
        onDelete: 'SET NULL'
      },
      name: { type: Sequelize.STRING(100), allowNull: false },
      sku: { type: Sequelize.STRING(50), allowNull: true },
      price: { type: Sequelize.DECIMAL(10, 2), allowNull: false, defaultValue: 0.00 },
      stock: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
      category: { type: Sequelize.STRING(50) },
      total_quantity: { type: Sequelize.INTEGER, defaultValue: 0 },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') }
    });
    await queryInterface.addConstraint('products', {
      fields: ['tenant_id', 'sku'],
      type: 'unique',
      name: 'unique_tenant_sku'
    });
    await queryInterface.addIndex('products', ['name']);
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('products');
  }
};
