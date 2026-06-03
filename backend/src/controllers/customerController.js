const Customer = require('../models/Customer');
const { ValidationError } = require('sequelize');

// @desc    Get all customers for a tenant
// @route   GET /api/customers
// @access  Private
const getCustomers = async (req, res) => {
    try {
        const customers = await Customer.findAll({
            where: { tenant_id: req.user.tenant_id },
            order: [['name', 'ASC']]
        });
        res.json(customers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new customer
// @route   POST /api/customers
// @access  Private
const createCustomer = async (req, res) => {
    const { name, phone, email, address } = req.body;

    try {
        if (!name || !phone) {
            return res.status(400).json({ message: 'Magaca iyo telefoonka waa qasab.' });
        }

        const customer = await Customer.create({
            tenant_id: req.user.tenant_id,
            branch_id: req.user?.branch_id ?? null,
            name,
            phone,
            email: email ?? null,
            address: address ?? null,
            debt_balance: 0.00,
        });

        res.status(201).json(customer);
    } catch (error) {
        if (error instanceof ValidationError) {
            return res.status(400).json({ message: error.errors?.[0]?.message || 'Customer validation failed.' });
        }
        res.status(500).json({ message: 'Server error while creating customer.' });
    }
};

// @desc    Update a customer
// @route   PUT /api/customers/:id
// @access  Private
const updateCustomer = async (req, res) => {
    try {
        const customer = await Customer.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (!customer) {
            return res.status(404).json({ message: 'Macmiilka lama helin' });
        }

        const { name, phone, email, address } = req.body;

        customer.name = name || customer.name;
        customer.phone = phone || customer.phone;
        customer.email = email || customer.email;
        customer.address = address || customer.address;

        const updated = await customer.save();
        res.json(updated);
    } catch (error) {
        if (error instanceof ValidationError) {
            return res.status(400).json({ message: error.errors?.[0]?.message || 'Customer validation failed.' });
        }
        res.status(500).json({ message: 'Server error while updating customer.' });
    }
};

// @desc    Delete a customer
// @route   DELETE /api/customers/:id
// @access  Private
const deleteCustomer = async (req, res) => {
    try {
        const customer = await Customer.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (!customer) {
            return res.status(404).json({ message: 'Macmiilka lama helin' });
        }

        await customer.destroy();
        res.json({ message: 'Macmiilka waa la tirtiray' });
    } catch (error) {
        res.status(500).json({ message: 'Server error while deleting customer.' });
    }
};

// @desc    Get customer by ID with debt details
// @route   GET /api/customers/:id
// @access  Private
const getCustomerById = async (req, res) => {
    try {
        const customer = await Customer.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (customer) {
            res.json(customer);
        } else {
            res.status(404).json({ message: 'Macmiilka lama helin' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error while loading customer.' });
    }
};

const getDebtors = async (req, res) => {
    try {
        const debtors = await Customer.findAll({
            where: {
                tenant_id: req.user.tenant_id,
                debt_balance: { [require('sequelize').Op.gt]: 0 }
            },
            order: [['debt_balance', 'DESC']]
        });
        res.json(debtors);
    } catch (error) {
        res.status(500).json({ message: 'Server error while loading debtors.' });
    }
};

const getCustomerHistory = async (req, res) => {
    try {
        const Sale = require('../models/Sale');
        const Payment = require('../models/Payment');
        const { Op } = require('sequelize');

        const customerId = req.params.id;
        const { startDate, endDate } = req.query;

        const parseDayStart = (value) => {
            const day = String(value).split('T')[0];
            const [y, m, d] = day.split('-').map(Number);
            return new Date(y, m - 1, d, 0, 0, 0, 0);
        };

        const parseDayEnd = (value) => {
            const day = String(value).split('T')[0];
            const [y, m, d] = day.split('-').map(Number);
            return new Date(y, m - 1, d, 23, 59, 59, 999);
        };

        const saleWhere = {
            customer_id: customerId,
            tenant_id: req.user.tenant_id,
        };

        if (startDate && endDate) {
            saleWhere.sale_date = {
                [Op.between]: [parseDayStart(startDate), parseDayEnd(endDate)],
            };
        } else if (startDate) {
            saleWhere.sale_date = { [Op.gte]: parseDayStart(startDate) };
        } else if (endDate) {
            saleWhere.sale_date = { [Op.lte]: parseDayEnd(endDate) };
        }

        const sales = await Sale.findAll({
            where: saleWhere,
            order: [['sale_date', 'DESC'], ['created_at', 'DESC']],
        });

        const paymentWhere = {
            customer_id: customerId,
            tenant_id: req.user.tenant_id,
        };
        if (startDate && endDate) {
            paymentWhere.payment_date = {
                [Op.between]: [parseDayStart(startDate), parseDayEnd(endDate)],
            };
        }

        const payments = await Payment.findAll({
            where: paymentWhere,
            order: [['payment_date', 'DESC'], ['created_at', 'DESC']],
        });

        const summary = {
            totalSales: sales.length,
            totalAmount: sales.reduce((sum, s) => sum + parseFloat(s.total_amount || 0), 0),
            totalPaid: sales.reduce((sum, s) => sum + parseFloat(s.paid_amount || 0), 0),
            totalDebt: sales.reduce((sum, s) => sum + parseFloat(s.debt_amount || 0), 0),
        };

        res.json({ sales, payments, summary });
    } catch (error) {
        res.status(500).json({ message: 'Server error while loading customer history.' });
    }
};

module.exports = {
    getCustomers,
    createCustomer,
    getCustomerById,
    getDebtors,
    getCustomerHistory,
    updateCustomer,
    deleteCustomer
};
