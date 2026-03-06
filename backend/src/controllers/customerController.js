const Customer = require('../models/Customer');

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
        const customer = await Customer.create({
            tenant_id: req.user.tenant_id,
            branch_id: req.user.branch_id,
            name,
            phone,
            email,
            address,
            debt_balance: 0.00
        });

        res.status(201).json(customer);
    } catch (error) {
        res.status(500).json({ message: error.message });
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
        res.status(500).json({ message: error.message });
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
        res.status(500).json({ message: error.message });
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
        res.status(500).json({ message: error.message });
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
        res.status(500).json({ message: error.message });
    }
};

const getCustomerHistory = async (req, res) => {
    try {
        const Sale = require('../models/Sale');
        const Payment = require('../models/Payment');

        const customerId = req.params.id;

        const sales = await Sale.findAll({
            where: { customer_id: customerId, tenant_id: req.user.tenant_id },
            order: [['created_at', 'DESC']]
        });

        const payments = await Payment.findAll({
            where: { customer_id: customerId, tenant_id: req.user.tenant_id },
            order: [['created_at', 'DESC']]
        });

        res.json({ sales, payments });
    } catch (error) {
        res.status(500).json({ message: error.message });
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
