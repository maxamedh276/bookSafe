const { sequelize } = require('./src/config/db');
const Product = require('./src/models/Product');
const User = require('./src/models/User');

const checkDB = async () => {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');
        const productCount = await Product.count();
        const userCount = await User.count();
        console.log(`Products: ${productCount}`);
        console.log(`Users: ${userCount}`);
        process.exit(0);
    } catch (error) {
        console.error('Unable to connect to the database:', error);
        process.exit(1);
    }
};

checkDB();
