const { sequelize } = require('../config/db');
const Sale = require('../models/Sale');
const SaleItem = require('../models/SaleItem');
const Product = require('../models/Product');
const Customer = require('../models/Customer');

// @desc    Create a new sale
// @route   POST /api/sales
// @access  Private
const createSale = async (req, res) => {
    const {
        customer_id,
        items, // Array of { product_id, quantity, price }
        paid_amount,
        payment_status
    } = req.body;

    const t = await sequelize.transaction();

    try {
        let total_amount = 0;

        // 1. Validate items and calculate total
        for (const item of items) {
            const product = await Product.findByPk(item.product_id, { transaction: t });

            const sameBranch = product && (product.branch_id === req.user.branch_id || product.branch_id == null);
            if (!product || !sameBranch) {
                throw new Error(`Alaabta ID-geedu yahay ${item.product_id} lama helin ama ma taalo laantan.`);
            }

            const qty = Number(item.quantity) || 0;
            const unitPrice = Number(item.price) || 0;
            if (qty <= 0) {
                throw new Error(`Quantity khaldan ayaa la soo diray (product_id=${item.product_id}).`);
            }
            if (unitPrice <= 0) {
                throw new Error(`Qiime khaldan ayaa la soo diray (product_id=${item.product_id}).`);
            }

            if (product.stock < qty) {
                throw new Error(`Alaabta ${product.name} stock-geedu kuma filna. (Hadda: ${product.stock})`);
            }
            total_amount += qty * unitPrice;
        }

        const debt_amount = payment_status === 'credit' ? total_amount - paid_amount : 0;
        const invoice_number = `INV-${Date.now()}`; // Simple unique invoice number generation

        // 2. Create Sale
        const sale = await Sale.create({
            tenant_id: req.user.tenant_id,
            branch_id: req.user.branch_id,
            user_id: req.user.id,
            customer_id: customer_id || null,
            total_amount,
            paid_amount: paid_amount || 0,
            debt_amount,
            payment_status,
            invoice_number,
        }, { transaction: t });

        // 3. Create Sale Items and Update Stock
        for (const item of items) {
            await SaleItem.create({
                sale_id: sale.id,
                product_id: item.product_id,
                quantity: item.quantity,
                price: item.price,
                subtotal: item.quantity * item.price,
            }, { transaction: t });

            // Decrease stock
            const product = await Product.findByPk(item.product_id, { transaction: t });
            product.stock -= item.quantity;
            await product.save({ transaction: t });
        }

        // 4. Update Customer Debt if applicable
        if (payment_status === 'credit' && customer_id) {
            const customer = await Customer.findByPk(customer_id, { transaction: t });
            if (customer) {
                customer.debt_balance = parseFloat(customer.debt_balance) + debt_amount;
                await customer.save({ transaction: t });
            } else {
                throw new Error('Macmiilka lama helin si deynta loogu qoro.');
            }
        }

        await t.commit();
        res.status(201).json(sale);

    } catch (error) {
        await t.rollback();
        res.status(400).json({ message: error.message });
    }
};

// @desc    Get all sales for a branch
// @route   GET /api/sales
// @access  Private
const getSales = async (req, res) => {
    try {
        const sales = await Sale.findAll({
            where: {
                tenant_id: req.user.tenant_id,
                branch_id: req.user.branch_id
            },
            include: [
                { model: Customer, attributes: ['name', 'phone'] },
                { model: SaleItem, as: 'items', include: [Product] }
            ],
            order: [['created_at', 'DESC']]
        });
        res.json(sales);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createSale,
    getSales
};
