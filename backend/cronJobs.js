const Tenant = require('./src/models/Tenant');
const { Op } = require('sequelize');

/**
 * Cron Job: Waxay maalin kasta hubisaa tenants-ka subscription-koodu dhacay.
 * Haddii dhacay waxay ka bedeshaa status-kooda 'suspended'.
 * 
 * Usage: Run using node-cron or a scheduled task.
 * Example: node cronJobs.js
 * 
 * To automate, add to server.js via node-cron package.
 */
const checkExpiredSubscriptions = async () => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const expired = await Tenant.findAll({
            where: {
                expiry_date: { [Op.lt]: today },
                status: 'active'
            }
        });

        if (expired.length === 0) {
            console.log('✅ [Cron] No expired subscriptions found.');
            return;
        }

        for (const tenant of expired) {
            await tenant.update({ status: 'suspended' });
            console.log(`⚠️ [Cron] Tenant "${tenant.business_name}" (ID: ${tenant.id}) waxaa la xidaa sababtoo ah subscription-kiisii wuu dhacay.`);
        }

        console.log(`✅ [Cron] ${expired.length} tenant(s) ayaa la xidey.`);
    } catch (error) {
        console.error('❌ [Cron] Error checking subscriptions:', error.message);
    }
};

// Export for use in server.js with node-cron
module.exports = { checkExpiredSubscriptions };

// Allow direct execution
if (require.main === module) {
    const db = require('./src/config/db');
    db.connectDB().then(() => {
        checkExpiredSubscriptions().then(() => process.exit(0));
    });
}
