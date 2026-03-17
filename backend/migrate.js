require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const migrate = async () => {
    const connectionString = process.argv[2] || process.env.DATABASE_URL;

    if (!connectionString) {
        console.error("❌ ERROR: Fadlan soo raaci Render Database URL-ka amarkaaga.");
        console.log("-> Sidaan u isticmaal (Tusaale):");
        console.log('-> node migrate.js "postgres://user:password@hostname.render.com/dbname"');
        process.exit(1);
    }

    const client = new Client({
        connectionString,
        ssl: {
            rejectUnauthorized: false // Required for Render Postgres
        }
    });

    try {
        console.log("🔌 Connecting to Render PostgreSQL Database...");
        await client.connect();
        console.log("✅ Connected successfully!");

        const sqlFilePath = path.join(__dirname, '..', 'booksafe_postgres_migration.sql');
        console.log(`🚀 Reading and executing migration script from: ${sqlFilePath}`);
        
        const sqlQuery = fs.readFileSync(sqlFilePath, 'utf8');

        // Execute queries
        await client.query(sqlQuery);

        console.log("🎉 Database migrated to PostgreSQL on Render successfully!");
        console.log("All tables and data have been correctly inserted.");

    } catch (error) {
        console.error("❌ Migration failed with error:");
        console.error(error);
    } finally {
        await client.end();
    }
};

migrate();
