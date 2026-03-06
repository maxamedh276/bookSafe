const { sequelize } = require('./src/config/db');
const Tenant = require('./src/models/Tenant');

const checkTenants = async () => {
    try {
        await sequelize.authenticate();
        const tenants = await Tenant.findAll();
        console.log(JSON.stringify(tenants, null, 2));
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

checkTenants();
