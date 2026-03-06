const User = require('./src/models/User');
const { connectDB, sequelize } = require('./src/config/db');
require('dotenv').config();

const createAdmin = async () => {
    try {
        await connectDB();

        const adminEmail = 'admin@booksafe.com';
        const adminPassword = 'adminpassword123';

        const existingAdmin = await User.findOne({ where: { email: adminEmail } });

        if (existingAdmin) {
            console.log('⚠️ IT Admin hore ayaa loo abuuray.');
        } else {
            await User.create({
                full_name: 'Super IT Admin',
                email: adminEmail,
                password: adminPassword,
                role: 'it_admin',
                status: 'active',
            });
            console.log('✅ IT Admin si guul leh ayaa loo abuuray.');
            console.log(`Email: ${adminEmail}`);
            console.log(`Password: ${adminPassword}`);
        }
    } catch (error) {
        console.error('❌ Error creating admin:', error.message);
    } finally {
        process.exit();
    }
};

createAdmin();
