const { sequelize } = require('../config/db');
const Sale = require('../models/Sale');
const SaleItem = require('../models/SaleItem');
const Product = require('../models/Product');
const Customer = require('../models/Customer');

const roundQty = (value) => Math.round(Number(value) * 1000) / 1000;

// @desc    Create a new sale
// @route   POST /api/sales
// @access  Private
const createSale = async (req, res) => {
    const {
        customer_id,
        items, // Array of { product_id, quantity, price }
        paid_amount,
        payment_status,
        discount,
        description
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

            const qty = roundQty(item.quantity);
            const unitPrice = Number(item.price) || 0;
            if (qty <= 0) {
                throw new Error(`Quantity khaldan ayaa la soo diray (product_id=${item.product_id}).`);
            }
            if (unitPrice <= 0) {
                throw new Error(`Qiime khaldan ayaa la soo diray (product_id=${item.product_id}).`);
            }

            const currentStock = roundQty(product.stock);
            if (currentStock < qty) {
                throw new Error(`Alaabta ${product.name} stock-geedu kuma filna. (Hadda: ${currentStock})`);
            }
            total_amount += qty * unitPrice;
        }

        const parsedDiscount = Number(discount) || 0;
        total_amount = Math.max(0, total_amount - parsedDiscount);
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
            discount: parsedDiscount,
            description: description || null,
            total_quantity: items.reduce((acc, item) => acc + roundQty(item.quantity), 0),
            payment_status,
            invoice_number,
        }, { transaction: t });

        // 3. Create Sale Items and Update Stock
        for (const item of items) {
            const qty = roundQty(item.quantity);
            const unitPrice = Number(item.price) || 0;
            await SaleItem.create({
                sale_id: sale.id,
                product_id: item.product_id,
                quantity: qty,
                price: unitPrice,
                subtotal: Math.round(qty * unitPrice * 100) / 100,
            }, { transaction: t });

            const product = await Product.findByPk(item.product_id, { transaction: t });
            product.stock = roundQty(Number(product.stock) - qty);
            product.total_quantity = roundQty(Number(product.total_quantity || 0) + qty);
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
