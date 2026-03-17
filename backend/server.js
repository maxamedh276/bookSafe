const app = require('./src/app');
const { connectDB, sequelize } = require('./src/config/db');
require('./src/models'); // Load models and associations
const cron = require('node-cron');
const { checkExpiredSubscriptions } = require('./cronJobs');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
    // Connect to Database
    await connectDB();

    // Sync Models
    const syncOptions = process.env.NODE_ENV === 'production' ? {} : { alter: true };
    await sequelize.sync(syncOptions);
    console.log('✅ Models synchronized...');

    app.listen(PORT, () => {
        console.log(`🚀 Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
    });

    // ── Cron Jobs ──────────────────────────────────────────────────────────────
    // Run every day at midnight: check expired subscriptions → suspend tenants
    cron.schedule('0 0 * * *', async () => {
        console.log('⏰ [Cron] Running daily subscription check...');
        await checkExpiredSubscriptions();
    }, {
        timezone: 'Africa/Nairobi' // EAT (UTC+3) — Somalia time
    });

    console.log('⏰ Daily subscription cron job scheduled (00:00 EAT).');
};

startServer();
