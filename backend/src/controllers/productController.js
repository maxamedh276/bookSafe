const { Product, Unit } = require('../models');

// @desc    Get all products for tenant
// @route   GET /api/products
// @access  Private
const getProducts = async (req, res) => {
    try {
        const where = {};

        // IT Admin: can see ALL tenants' products
        if (req.user.role !== 'it_admin') {
            // Tenant + all branches: show all products that belong to this tenant
            where.tenant_id = req.user.tenant_id;
        }

        const products = await Product.findAll({
            where,
            include: [{ model: Unit, as: 'unit', attributes: ['id', 'name', 'short_name'] }],
            order: [['name', 'ASC']],
        });

        res.json(products);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new product
// @route   POST /api/products
// @access  Private (Manager, Cashier)
const createProduct = async (req, res) => {
    const { name, sku, price, stock, category, unit_id } = req.body;

    try {
        // Check if SKU exists for this tenant
        if (sku) {
            const skuExists = await Product.findOne({
                where: { tenant_id: req.user.tenant_id, sku }
            });
            if (skuExists) {
                return res.status(400).json({ message: 'SKU-gan hore ayaa loo isticmaalay' });
            }
        }

        const product = await Product.create({
            tenant_id: req.user.tenant_id,
            branch_id: req.user.branch_id,
            name,
            sku,
            price,
            stock,
            category,
            unit_id: unit_id || null
        });

        res.status(201).json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update a product
// @route   PUT /api/products/:id
// @access  Private
const updateProduct = async (req, res) => {
    try {
        const product = await Product.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (product) {
            const { name, sku, price, stock, category, unit_id } = req.body;

            product.name = name || product.name;
            product.sku = sku || product.sku;
            product.price = price || product.price;
            product.stock = stock !== undefined ? stock : product.stock;
            product.category = category || product.category;
            product.unit_id = unit_id !== undefined ? unit_id : product.unit_id;

            const updatedProduct = await product.save();
            const productWithUnit = await Product.findByPk(updatedProduct.id, {
                include: [{ model: Unit, as: 'unit', attributes: ['id', 'name', 'short_name'] }]
            });
            res.json(productWithUnit);
        } else {
            res.status(404).json({ message: 'Alaabta lama helin' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete a product
// @route   DELETE /api/products/:id
// @access  Private (Admin, Manager)
const deleteProduct = async (req, res) => {
    try {
        const product = await Product.findOne({
            where: { id: req.params.id, tenant_id: req.user.tenant_id }
        });

        if (product) {
            await product.destroy();
            res.json({ message: 'Alaabta waa la tirtiray' });
        } else {
            res.status(404).json({ message: 'Alaabta lama helin' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getProducts,
    createProduct,
    updateProduct,
    deleteProduct
};
