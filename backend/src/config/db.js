const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = process.env.DATABASE_URL 
  ? new Sequelize(process.env.DATABASE_URL, {
      dialect: 'postgres',
      protocol: 'postgres',
      logging: false,
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: false, // required for Render
        },
      },
      pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000,
      },
    })
  : new Sequelize(process.env.DB_NAME, process.env.DB_USER, process.env.DB_PASS, {
      host: process.env.DB_HOST,
      dialect: 'postgres',
      logging: false,
    });

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ PostgreSQL Database connected...');
  } catch (error) {
    console.error('❌ Unable to connect to the database:', error);
    process.exit(1);
  }
};

module.exports = { sequelize, connectDB };
