const { sequelize } = require('../config/db');
const Payment = require('../models/Payment');
const Customer = require('../models/Customer');
const Sale = require('../models/Sale');

// @desc    Record a debt payment from a customer
// @route   POST /api/payments
// @access  Private
const recordPayment = async (req, res) => {
    const { customer_id, sale_id, amount, payment_method } = req.body;

    const t = await sequelize.transaction();

    try {
        // 1. Find the customer
        const customer = await Customer.findOne({
            where: { id: customer_id, tenant_id: req.user.tenant_id },
            transaction: t
        });

        if (!customer) {
            throw new Error('Macmiilka lama helin.');
        }

        // 2. Create the payment record
        const payment = await Payment.create({
            tenant_id: req.user.tenant_id,
            branch_id: req.user.branch_id,
            customer_id,
            sale_id: sale_id || null,
            amount,
            payment_method,
            payment_date: new Date()
        }, { transaction: t });

        // 3. Update customer's debt balance
        customer.debt_balance = parseFloat(customer.debt_balance) - parseFloat(amount);
        await customer.save({ transaction: t });

        // 4. Update specific sale OR distribute across all credit sales
        if (sale_id) {
            const sale = await Sale.findOne({
                where: { id: sale_id, tenant_id: req.user.tenant_id },
                transaction: t
            });
            if (sale) {
                sale.paid_amount = parseFloat(sale.paid_amount) + parseFloat(amount);
                sale.debt_amount = parseFloat(sale.debt_amount) - parseFloat(amount);

                if (parseFloat(sale.debt_amount) <= 0) {
                    sale.payment_status = 'paid';
                }
                await sale.save({ transaction: t });
            }
        } else {
            // General payment: Distribute across older credit sales first (FIFO)
            const creditSales = await Sale.findAll({
                where: {
                    customer_id,
                    tenant_id: req.user.tenant_id,
                    payment_status: 'credit'
                },
                order: [['created_at', 'ASC']],
                transaction: t
            });

            let remainingAmount = parseFloat(amount);
            for (const sale of creditSales) {
                if (remainingAmount <= 0) break;

                const saleDebt = parseFloat(sale.debt_amount);
                const paymentForThisSale = Math.min(remainingAmount, saleDebt);

                sale.paid_amount = parseFloat(sale.paid_amount) + paymentForThisSale;
                sale.debt_amount = parseFloat(sale.debt_amount) - paymentForThisSale;

                if (sale.debt_amount <= 0) {
                    sale.payment_status = 'paid';
                }

                await sale.save({ transaction: t });
                remainingAmount -= paymentForThisSale;
            }
        }

        await t.commit();
        res.status(201).json({
            message: 'Lacag bixinta deynta si guul leh ayaa loo diiwangeliyey.',
            payment,
            remaining_debt: customer.debt_balance
        });

    } catch (error) {
        await t.rollback();
        res.status(400).json({ message: error.message });
    }
};

// @desc    Get all payments for a branch
// @route   GET /api/payments
// @access  Private
const getPayments = async (req, res) => {
    try {
        const payments = await Payment.findAll({
            where: {
                tenant_id: req.user.tenant_id,
                branch_id: req.user.branch_id
            },
            include: [{ model: Customer, attributes: ['name', 'phone'] }],
            order: [['created_at', 'DESC']]
        });
        res.json(payments);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    recordPayment,
    getPayments
};
