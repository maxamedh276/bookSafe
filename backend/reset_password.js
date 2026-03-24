require('dotenv').config();
const { Client } = require('pg');
const bcrypt = require('bcryptjs');

const reset = async () => {
    const connectionString = process.argv[2] || process.env.DATABASE_URL;

    if (!connectionString) {
        console.error("❌ ERROR: DATABASE_URL is missing in .env.");
        process.exit(1);
    }

    const client = new Client({
        connectionString,
        ssl: { rejectUnauthorized: false }
    });

    try {
        await client.connect();
        
        // Abuurida sir siraysan (hashed password) oo ah '123456'
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('123456', salt);
        
        // Bedelida password-ka mohamed@gmail.com
        await client.query("UPDATE users SET password = $1 WHERE email = $2", [hashedPassword, 'mohamed@gmail.com']);
        console.log("✅ Password-kii mohamed@gmail.com waxaa laga dhigay: 123456");
        
        // Bedelida password-ka admin@booksafe.com (si asigana aad u isticmaali kartid goor walba)
        await client.query("UPDATE users SET password = $1 WHERE email = $2", [hashedPassword, 'admin@booksafe.com']);
        console.log("✅ Password-kii admin@booksafe.com waxaa laga dhigay: 123456");

    } catch (error) {
        console.error("❌ Cilad baa dhacday:", error);
    } finally {
        await client.end();
    }
};

reset();
