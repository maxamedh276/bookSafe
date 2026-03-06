const { sequelize } = require('./src/config/db');
const Tenant = require('./src/models/Tenant');
const Branch = require('./src/models/Branch');
const User = require('./src/models/User');

const checkFullStatus = async () => {
    try {
        await sequelize.authenticate();
        const tenantCount = await Tenant.count();
        const branchCount = await Branch.count();
        const userCount = await User.count();
        const users = await User.findAll({ attributes: ['email', 'role', 'tenant_id', 'branch_id'] });

        console.log(`Tenants: ${tenantCount}`);
        console.log(`Branches: ${branchCount}`);
        console.log(`Users: ${userCount}`);
        console.log('User Details:');
        users.forEach(u => {
            console.log(`- ${u.email} (${u.role}) TenantID: ${u.tenant_id} BranchID: ${u.branch_id}`);
        });
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

checkFullStatus();
