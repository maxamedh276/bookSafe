require('dotenv').config();
const { sequelize } = require('./src/config/db');
const { Unit } = require('./src/models');

const units = [
    { name: 'Kilogram', abbreviation: 'kg' },
    { name: 'Gram', abbreviation: 'g' },
    { name: 'Milligram', abbreviation: 'mg' },
    { name: 'Pound', abbreviation: 'lb' },
    { name: 'Ounce', abbreviation: 'oz' },
    { name: 'Liter', abbreviation: 'l' },
    { name: 'Milliliter', abbreviation: 'ml' },
    { name: 'Piece', abbreviation: 'pcs' },
    { name: 'Box', abbreviation: 'box' },
    { name: 'Dozen', abbreviation: 'dz' },
    { name: 'Meter', abbreviation: 'm' },
    { name: 'Centimeter', abbreviation: 'cm' },
    { name: 'Feet', abbreviation: 'ft' },
    { name: 'Inch', abbreviation: 'in' },
    { name: 'Pack', abbreviation: 'pack' },
    { name: 'Set', abbreviation: 'set' },
    { name: 'Bottle', abbreviation: 'btl' },
    { name: 'Can', abbreviation: 'can' },
    { name: 'Carton', abbreviation: 'ctn' },
    { name: 'Pair', abbreviation: 'pair' },
    { name: 'Roll', abbreviation: 'roll' },
    { name: 'Bag', abbreviation: 'bag' },
    { name: 'Sack', abbreviation: 'sack' },
    { name: 'Bucket', abbreviation: 'bkt' },
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
