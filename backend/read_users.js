const User = require('./src/models/User');
const Tenant = require('./src/models/Tenant');
const { connectDB } = require('./src/config/db');
require('dotenv').config();

const showUsers = async () => {
    try {
        await connectDB();
        
        console.log('\n--- SYSTEM USERS ---');
        const users = await User.findAll({
            include: [{ model: Tenant, required: false }]
        });
        
        if (users.length === 0) {
            console.log('No users found in the database.');
        } else {
            users.forEach(user => {
                console.log(`ID: ${user.id}`);
                console.log(`Full Name: ${user.full_name}`);
                console.log(`Email: ${user.email}`);
                console.log(`Role: ${user.role}`);
                console.log(`Status: ${user.status}`);
                if (user.Tenant) {
                    console.log(`Tenant (Business): ${user.Tenant.business_name} (ID: ${user.Tenant.id})`);
                } else {
                    console.log('Tenant: None (IT Admin)');
                }
                console.log('--------------------');
            });
        }
    } catch (error) {
        console.error('❌ Error reading users:', error.message);
    } finally {
        process.exit();
    }
};

showUsers();
