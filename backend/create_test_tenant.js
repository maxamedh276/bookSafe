const User = require('./src/models/User');
const Tenant = require('./src/models/Tenant');
const Branch = require('./src/models/Branch');
const { connectDB } = require('./src/config/db');
require('dotenv').config();

const createTestTenant = async () => {
    try {
        await connectDB();

        // 1. Create or Find Tenant
        const tenantEmail = 'shop@booksafe.com';
        const [tenant, tenantCreated] = await Tenant.findOrCreate({
            where: { email: tenantEmail },
            defaults: {
                business_name: 'BookSafe Local Shop',
                owner_name: 'Mohamed Local',
                phone: '615999999',
                address: 'Mogadishu, Somalia',
                subscription_plan: 'premium',
                status: 'active',
                branch_limit: 5,
                expiry_date: '2030-12-31'
            }
        });

        if (tenantCreated) {
            console.log('✅ Created Tenant: BookSafe Local Shop');
        } else {
            // Update to active just in case
            tenant.status = 'active';
            await tenant.save();
            console.log('ℹ️ Tenant already exists (Updated to Active)');
        }

        // 2. Create a default Branch for this tenant
        const [branch, branchCreated] = await Branch.findOrCreate({
            where: { tenant_id: tenant.id, branch_name: 'Mogadishu Branch' },
            defaults: {
                location: 'Maka Al Mukarama',
                phone: '615999999'
            }
        });

        if (branchCreated) {
            console.log('✅ Created Default Branch: Mogadishu Branch');
        }

        // 3. Create or Find Tenant Admin User
        const userEmail = 'shop@booksafe.com';
        const userPassword = 'password123';
        
        const existingUser = await User.findOne({ where: { email: userEmail } });

        if (existingUser) {
            // Update password and roles
            existingUser.password = userPassword;
            existingUser.role = 'tenant_admin';
            existingUser.status = 'active';
            existingUser.tenant_id = tenant.id;
            existingUser.branch_id = branch.id;
            await existingUser.save();
            console.log('✅ Updated existing User to Tenant Admin with password123');
        } else {
            await User.create({
                tenant_id: tenant.id,
                branch_id: branch.id,
                full_name: 'Mohamed Local Admin',
                email: userEmail,
                password: userPassword,
                role: 'tenant_admin',
                status: 'active'
            });
            console.log('✅ Created New Tenant Admin User:');
            console.log(`   Email: ${userEmail}`);
            console.log(`   Password: ${userPassword}`);
        }

        // Also update mohamed@gmail.com to make sure it has password123 and active status
        const mohamedUser = await User.findOne({ where: { email: 'mohamed@gmail.com' } });
        if (mohamedUser) {
            mohamedUser.password = 'password123';
            mohamedUser.status = 'active';
            mohamedUser.tenant_id = tenant.id;
            mohamedUser.branch_id = branch.id;
            await mohamedUser.save();
            console.log('✅ Updated mohamed@gmail.com password to: password123');
        }

    } catch (error) {
        console.error('❌ Error creating test tenant:', error.message);
    } finally {
        process.exit();
    }
};

createTestTenant();
