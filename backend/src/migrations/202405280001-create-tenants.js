module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('tenants', {
      id: { type: Sequelize.INTEGER, primaryKey: true, autoIncrement: true },
      business_name: { type: Sequelize.STRING(100), allowNull: false },
      owner_name: { type: Sequelize.STRING(100), allowNull: false },
      email: { type: Sequelize.STRING(100), allowNull: false, unique: true },
      phone: { type: Sequelize.STRING(20), allowNull: false },
      address: { type: Sequelize.TEXT },
      subscription_plan: { type: Sequelize.ENUM('basic', 'premium'), defaultValue: 'basic' },
      status: { type: Sequelize.ENUM('pending', 'active', 'suspended', 'blocked'), defaultValue: 'pending' },
      branch_limit: { type: Sequelize.INTEGER, defaultValue: 1 },
      expiry_date: { type: Sequelize.DATEONLY },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('tenants');
  },
};
