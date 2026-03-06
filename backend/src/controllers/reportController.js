const { Op } = require('sequelize');
const { sequelize } = require('../config/db');
const Sale = require('../models/Sale');
const SaleItem = require('../models/SaleItem');
const Product = require('../models/Product');
const Customer = require('../models/Customer');
const Payment = require('../models/Payment');

// @desc    Get sales analytics (Daily, Weekly, Monthly)
// @route   GET /api/reports/sales
// @access  Private (Admin, Manager)
const getSalesSummary = async (req, res) => {
    const { startDate, endDate } = req.query;

    try {
        const whereClause = {
            tenant_id: req.user.tenant_id,
            branch_id: req.user.branch_id,
        };

        if (startDate && endDate) {
            whereClause.sale_date = {
                [Op.between]: [new Date(startDate), new Date(endDate)],
            };
        }

        const sales = await Sale.findAll({ where: whereClause });

        const totalSales = sales.reduce((acc, sale) => acc + parseFloat(sale.total_amount), 0);
        const totalPaid = sales.reduce((acc, sale) => acc + parseFloat(sale.paid_amount), 0);
        const totalDebt = sales.reduce((acc, sale) => acc + parseFloat(sale.debt_amount), 0);
        const salesCount = sales.length;

        res.json({
            totalSales,
            totalPaid,
            totalDebt,
            salesCount,
            period: { startDate, endDate }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get top selling products
// @route   GET /api/reports/top-products
// @access  Private
const getTopProducts = async (req, res) => {
    try {
        const topProducts = await SaleItem.findAll({
            attributes: [
                'product_id',
                [sequelize.fn('SUM', sequelize.col('quantity')), 'totalQuantity'],
                [sequelize.fn('SUM', sequelize.col('subtotal')), 'totalRevenue'],
            ],
            include: [{ model: Product, attributes: ['name', 'price'] }],
            group: ['product_id', 'Product.id'],
            order: [[sequelize.literal('totalQuantity'), 'DESC']],
            limit: 10,
        });

        res.json(topProducts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get customers with most debt
// @route   GET /api/reports/debtors
// @access  Private
const getTopDebtors = async (req, res) => {
    try {
        const debtors = await Customer.findAll({
            where: {
                tenant_id: req.user.tenant_id,
                debt_balance: { [Op.gt]: 0 }
            },
            order: [['debt_balance', 'DESC']],
            limit: 20
        });
        res.json(debtors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get daily sales for chart (last 30 days)
// @route   GET /api/reports/daily-sales
// @access  Private
const getDailySales = async (req, res) => {
    try {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const sales = await Sale.findAll({
            where: {
                tenant_id: req.user.tenant_id,
                sale_date: { [Op.gte]: thirtyDaysAgo }
            },
            attributes: [
                [sequelize.fn('DATE', sequelize.col('sale_date')), 'date'],
                [sequelize.fn('SUM', sequelize.col('total_amount')), 'totalSales'],
                [sequelize.fn('SUM', sequelize.col('paid_amount')), 'totalPaid'],
                [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
            ],
            group: [sequelize.fn('DATE', sequelize.col('sale_date'))],
            order: [[sequelize.fn('DATE', sequelize.col('sale_date')), 'ASC']],
        });

        res.json(sales);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Export sales as CSV
// @route   GET /api/reports/export-csv
// @access  Private
const exportSalesCSV = async (req, res) => {
    const { startDate, endDate } = req.query;

    try {
        const whereClause = { tenant_id: req.user.tenant_id };
        if (startDate && endDate) {
            whereClause.sale_date = { [Op.between]: [new Date(startDate), new Date(endDate)] };
        }

        const sales = await Sale.findAll({
            where: whereClause,
            include: [
                { model: Customer, attributes: ['name', 'phone'] },
            ],
            order: [['sale_date', 'DESC']],
        });

        const rows = sales.map(s => [
            s.invoice_number,
            s.Customer?.name || 'N/A',
            s.Customer?.phone || '',
            parseFloat(s.total_amount).toFixed(2),
            parseFloat(s.paid_amount).toFixed(2),
            parseFloat(s.debt_amount).toFixed(2),
            s.payment_status,
            new Date(s.sale_date).toLocaleDateString(),
        ]);

        const header = ['Invoice', 'Customer', 'Phone', 'Total', 'Paid', 'Debt', 'Status', 'Date'];
        const csv = [header, ...rows].map(r => r.join(',')).join('\n');

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=sales-report.csv');
        res.send(csv);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getSalesSummary,
    getTopProducts,
    getTopDebtors,
    getDailySales,
    exportSalesCSV
};
