const mysql = require('mysql2/promise');
require('dotenv').config();

async function createDb() {
    console.log('🔌 Connecting to local MySQL as root...');
    let connection;
    try {
        connection = await mysql.createConnection({
            host: process.env.DB_HOST || 'localhost',
            user: 'root',
            password: '',
        });
        console.log('✅ Connected as root successfully.');
    } catch (rootError) {
        console.error('❌ Failed to connect as root (no password):', rootError.message);
        console.log('🔌 Trying to connect with .env credentials...');
        try {
            connection = await mysql.createConnection({
                host: process.env.DB_HOST,
                user: process.env.DB_USER,
                password: process.env.DB_PASS,
            });
            console.log('✅ Connected with .env credentials successfully.');
        } catch (envError) {
            console.error('❌ Failed to connect with both root and .env credentials:', envError.message);
            process.exit(1);
        }
    }

    try {
        const dbName = process.env.DB_NAME || 'booksafe_db';
        await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
        console.log(`✅ Database "${dbName}" created or already exists.`);

        // Create the user and grant privileges if connected as root
        try {
            const dbUser = process.env.DB_USER || 'booksafe_user';
            const dbPass = process.env.DB_PASS || 'StrongPass123!';
            
            // Check if user exists, if not create and grant
            await connection.query(`CREATE USER IF NOT EXISTS '${dbUser}'@'localhost' IDENTIFIED BY '${dbPass}';`);
            await connection.query(`GRANT ALL PRIVILEGES ON \`${dbName}\`.* TO '${dbUser}'@'localhost';`);
            await connection.query(`FLUSH PRIVILEGES;`);
            console.log(`✅ MySQL user "${dbUser}" created or updated and privileges granted.`);
        } catch (userError) {
            console.log('⚠️ Could not create/update user privileges (might not be root):', userError.message);
        }

    } catch (error) {
        console.error('❌ Error in database operations:', error.message);
    } finally {
        if (connection) {
            await connection.end();
        }
    }
}

createDb();
