/**
 * Runs decimal quantity migration + seeds Somali-friendly units (thm, qkg).
 * Usage: node run_decimal_migration.js
 */
require('dotenv').config();
const { sequelize } = require('./src/config/db');
require('./src/models');
const migration = require('./src/migrations/202406070001-decimal-quantities');
const { Unit } = require('./src/models');

const extraUnits = [
    { name: 'Handful', shortName: 'thm' },
    { name: 'Quarter Kilo', shortName: 'qkg' },
];

const run = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Database connected.');

        console.log('🔄 Applying decimal quantity migration...');
        await migration.up(sequelize.getQueryInterface(), sequelize.constructor);
        console.log('✅ Decimal columns updated (stock, sale_items.quantity, total_quantity).');

        console.log('🌱 Seeding extra units (Thumun, Rubac kilo)...');
        for (const unit of extraUnits) {
            const [row, created] = await Unit.findOrCreate({
                where: { name: unit.name },
                defaults: unit,
            });
            console.log(created ? `   + ${row.name} (${row.shortName})` : `   = ${row.name} already exists`);
        }

        console.log('✅ Migration complete. Restart backend server if it is running.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        if (error.original) console.error(error.original.message || error.original);
        process.exit(1);
    }
};

run();
