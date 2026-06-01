require('dotenv').config();
const { sequelize } = require('./src/config/db');
const { Unit } = require('./src/models');

const units = [
    { name: 'Kilogram', shortName: 'kg' },
    { name: 'Gram', shortName: 'g' },
    { name: 'Milligram', shortName: 'mg' },
    { name: 'Pound', shortName: 'lb' },
    { name: 'Ounce', shortName: 'oz' },
    { name: 'Liter', shortName: 'l' },
    { name: 'Milliliter', shortName: 'ml' },
    { name: 'Piece', shortName: 'pcs' },
    { name: 'Box', shortName: 'box' },
    { name: 'Dozen', shortName: 'dz' },
    { name: 'Meter', shortName: 'm' },
    { name: 'Centimeter', shortName: 'cm' },
    { name: 'Feet', shortName: 'ft' },
    { name: 'Inch', shortName: 'in' },
    { name: 'Pack', shortName: 'pack' },
    { name: 'Set', shortName: 'set' },
    { name: 'Bottle', shortName: 'btl' },
    { name: 'Can', shortName: 'can' },
    { name: 'Carton', shortName: 'ctn' },
    { name: 'Pair', shortName: 'pair' },
    { name: 'Roll', shortName: 'roll' },
    { name: 'Bag', shortName: 'bag' },
    { name: 'Sack', shortName: 'sack' },
    { name: 'Bucket', shortName: 'bkt' },
];

const syncAndSeed = async () => {
    try {
        console.log('🔄 Syncing database models...');
        // Using alter: true to add new columns without dropping data
        await sequelize.sync({ alter: true });
        console.log('✅ Database models synced.');

        console.log('🌱 Seeding units...');
        for (const unit of units) {
            await Unit.findOrCreate({
                where: { name: unit.name },
                defaults: unit
            });
        }
        console.log('✅ Units seeded successfully.');
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Sync/Seed failed:', error);
        process.exit(1);
    }
};

syncAndSeed();
