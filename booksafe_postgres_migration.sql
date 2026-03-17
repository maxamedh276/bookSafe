-- ==========================================================
-- PostgreSQL Migration Script for BookSafe ERP System
-- Converted from MySQL (booksafe_db.sql)
-- ==========================================================

-- Disable foreign key checks for manual insertion might be tricky in pure Postgres,
-- but we are inserting in proper relational order:
-- tenants -> branches -> users -> customers -> products -> sales -> sale_items -> payments -> subscription_payments -> audit_logs

-- --------------------------------------------------------
-- TABLE: tenants
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS tenants (
  id SERIAL PRIMARY KEY,
  business_name VARCHAR(100) NOT NULL,
  owner_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(20) NOT NULL,
  address TEXT,
  subscription_plan VARCHAR(255) DEFAULT 'basic',
  status VARCHAR(255) DEFAULT 'pending',
  branch_limit INT DEFAULT 1,
  expiry_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO tenants (id, business_name, owner_name, email, phone, address, subscription_plan, status, branch_limit, expiry_date, created_at, updated_at) VALUES
(1, 'BookSafe Shop', 'Maxamed Xasan Ibrahim', 'mohamed@gmail.com', '615240810', 'Mogadishu, somalia', 'basic', 'active', 1, '2027-03-31', '2026-02-27 16:06:37', '2026-02-27 19:43:32'),
(2, 'Imtixaan Shop', 'Axmed Cali', 'test_1772485694618@imtixaan.com', '615123456', 'Maka Al Mukarama, Mogadishu', 'basic', 'active', 1, '2027-01-01', '2026-03-02 21:08:14', '2026-03-02 21:08:15')
ON CONFLICT (id) DO NOTHING;

SELECT setval('tenants_id_seq', COALESCE((SELECT MAX(id)+1 FROM tenants), 1), false);

-- --------------------------------------------------------
-- TABLE: branches
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS branches (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE,
  branch_name VARCHAR(100) NOT NULL,
  location VARCHAR(255),
  phone VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO branches (id, tenant_id, branch_name, location, phone, created_at, updated_at) VALUES
(1, 1, 'Main Branch', 'Mogadishu, somalia', '615240810', '2026-02-27 16:06:37', '2026-02-27 16:06:37'),
(2, 2, 'Main Branch', 'Maka Al Mukarama, Mogadishu', '615123456', '2026-03-02 21:08:14', '2026-03-02 21:08:14')
ON CONFLICT (id) DO NOTHING;

SELECT setval('branches_id_seq', COALESCE((SELECT MAX(id)+1 FROM branches), 1), false);

-- --------------------------------------------------------
-- TABLE: users
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id) ON DELETE SET NULL ON UPDATE CASCADE,
  branch_id INT REFERENCES branches(id) ON DELETE SET NULL ON UPDATE CASCADE,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(255) DEFAULT 'cashier',
  status VARCHAR(255) DEFAULT 'active',
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO users (id, tenant_id, branch_id, full_name, email, password, role, status, last_login, created_at, updated_at) VALUES
(1, NULL, NULL, 'Super IT Admin', 'admin@booksafe.com', '$2b$10$cWbAZ8YAjbuzmOHHXO2R8OUcJ1E0xsih9yXJR37kum6oUlGr9Pahm', 'it_admin', 'active', '2026-03-02 21:08:15', '2026-02-27 15:02:10', '2026-03-02 21:08:15'),
(2, 1, 1, 'Maxamed Xasan Ibrahim', 'mohamed@gmail.com', '$2b$10$9lVXqCwrfros.3PdtGcoZON0KzkT2HD05.LjlYaIjzuySqSBd5Vzu', 'branch_manager', 'active', '2026-03-06 13:44:17', '2026-02-27 16:06:37', '2026-03-06 13:44:17'),
(3, 2, 2, 'Axmed Cali', 'test_1772485694618@imtixaan.com', '$2b$10$za6v8EXHSamVNpqTWs7InuTnPjQHhdowx/bRQd6aEh4J6/P/M8jCS', 'tenant_admin', 'active', '2026-03-02 21:08:15', '2026-03-02 21:08:14', '2026-03-02 21:08:15')
ON CONFLICT (id) DO NOTHING;

SELECT setval('users_id_seq', COALESCE((SELECT MAX(id)+1 FROM users), 1), false);

-- --------------------------------------------------------
-- TABLE: customers
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE,
  branch_id INT NOT NULL REFERENCES branches(id) ON DELETE CASCADE ON UPDATE CASCADE,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(100),
  address TEXT,
  debt_balance NUMERIC(10,2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO customers (id, tenant_id, branch_id, name, phone, email, address, debt_balance, created_at, updated_at) VALUES
(1, 1, 1, 'ahmed', '12365665', 'ahmed@gmail.com', 'somali', 0.00, '2026-02-27 20:33:58', '2026-03-06 13:43:05'),
(2, 1, 1, 'xaafid', '2444444', 'xaafid@gmail.com', 'cali', 0.00, '2026-02-27 21:39:31', '2026-03-06 13:06:42'),
(3, 2, 2, 'Jaamac Faarax', '615001122', 'jaamac@test.com', NULL, 5.00, '2026-03-02 21:08:15', '2026-03-02 21:08:15')
ON CONFLICT (id) DO NOTHING;

SELECT setval('customers_id_seq', COALESCE((SELECT MAX(id)+1 FROM customers), 1), false);

-- --------------------------------------------------------
-- TABLE: products
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE,
  branch_id INT NOT NULL REFERENCES branches(id) ON DELETE CASCADE ON UPDATE CASCADE,
  name VARCHAR(100) NOT NULL,
  sku VARCHAR(50),
  price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  stock INT NOT NULL DEFAULT 0,
  category VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO products (id, tenant_id, branch_id, name, sku, price, stock, category, created_at, updated_at) VALUES
(1, 1, 1, 'Bariis', 'WAAw', 10.00, 9, 'meal', '2026-03-01 21:34:52', '2026-03-06 12:10:38'),
(2, 1, 1, 'bariis', NULL, 10.00, 12, NULL, '2026-03-02 21:04:04', '2026-03-06 13:05:27'),
(3, 1, 1, 'baasto', NULL, 10.00, 6, NULL, '2026-03-02 21:04:24', '2026-03-06 13:09:20'),
(4, 2, 2, 'Buskud', 'SKU-1772485695459', 0.50, 90, NULL, '2026-03-02 21:08:15', '2026-03-02 21:08:15')
ON CONFLICT (id) DO NOTHING;

SELECT setval('products_id_seq', COALESCE((SELECT MAX(id)+1 FROM products), 1), false);

-- --------------------------------------------------------
-- TABLE: sales
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE,
  branch_id INT NOT NULL REFERENCES branches(id),
  user_id INT NOT NULL REFERENCES users(id),
  customer_id INT REFERENCES customers(id) ON DELETE SET NULL ON UPDATE CASCADE,
  total_amount NUMERIC(10,2) NOT NULL,
  paid_amount NUMERIC(10,2) DEFAULT 0.00,
  debt_amount NUMERIC(10,2) DEFAULT 0.00,
  payment_status VARCHAR(255) NOT NULL,
  invoice_number VARCHAR(255) NOT NULL,
  sale_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO sales (id, tenant_id, branch_id, user_id, customer_id, total_amount, paid_amount, debt_amount, payment_status, invoice_number, sale_date, created_at, updated_at) VALUES
(1, 2, 2, 3, 3, 5.00, 0.00, 5.00, 'credit', 'INV-1772485695519', '2026-03-02 21:08:15', '2026-03-02 21:08:15', '2026-03-02 21:08:15'),
(2, 1, 1, 2, NULL, 40.00, 40.00, 0.00, 'paid', 'INV-1772799038849', '2026-03-06 12:10:38', '2026-03-06 12:10:38', '2026-03-06 12:10:38'),
(3, 1, 1, 2, 1, 10.00, 0.00, 10.00, 'credit', 'INV-1772802560667', '2026-03-06 13:09:20', '2026-03-06 13:09:20', '2026-03-06 13:09:20')
ON CONFLICT (id) DO NOTHING;

SELECT setval('sales_id_seq', COALESCE((SELECT MAX(id)+1 FROM sales), 1), false);

-- --------------------------------------------------------
-- TABLE: sale_items
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS sale_items (
  id SERIAL PRIMARY KEY,
  sale_id INT NOT NULL REFERENCES sales(id) ON DELETE CASCADE ON UPDATE CASCADE,
  product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
  quantity INT NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  subtotal NUMERIC(10,2) NOT NULL
);

INSERT INTO sale_items (id, sale_id, product_id, quantity, price, subtotal) VALUES
(1, 1, 4, 10, 0.50, 5.00),
(2, 2, 3, 3, 10.00, 30.00),
(3, 2, 1, 1, 10.00, 10.00),
(4, 3, 3, 1, 10.00, 10.00)
ON CONFLICT (id) DO NOTHING;

SELECT setval('sale_items_id_seq', COALESCE((SELECT MAX(id)+1 FROM sale_items), 1), false);

-- --------------------------------------------------------
-- TABLE: payments
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id),
  branch_id INT NOT NULL,
  customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE ON UPDATE CASCADE,
  sale_id INT REFERENCES sales(id),
  amount NUMERIC(10,2) NOT NULL,
  payment_date TIMESTAMP WITH TIME ZONE,
  payment_method VARCHAR(255) DEFAULT 'cash',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO payments (id, tenant_id, branch_id, customer_id, sale_id, amount, payment_date, payment_method, created_at, updated_at) VALUES
(1, 1, 1, 1, NULL, 10.00, '2026-03-06 13:43:05', 'cash', '2026-03-06 13:43:05', '2026-03-06 13:43:05')
ON CONFLICT (id) DO NOTHING;

SELECT setval('payments_id_seq', COALESCE((SELECT MAX(id)+1 FROM payments), 1), false);

-- --------------------------------------------------------
-- TABLE: subscription_payments
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscription_payments (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE,
  plan VARCHAR(50) NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  start_date DATE,
  end_date DATE,
  status VARCHAR(255) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- (empty in MySQL, so seq set to 1)
SELECT setval('subscription_payments_id_seq', COALESCE((SELECT MAX(id)+1 FROM subscription_payments), 1), false);

-- --------------------------------------------------------
-- TABLE: audit_logs
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
  id SERIAL PRIMARY KEY,
  tenant_id INT NOT NULL REFERENCES tenants(id),
  user_id INT NOT NULL REFERENCES users(id),
  action VARCHAR(50) NOT NULL,
  table_name VARCHAR(50) NOT NULL,
  record_id INT,
  old_value JSONB,
  new_value JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO audit_logs (id, tenant_id, user_id, action, table_name, record_id, old_value, new_value, created_at) VALUES
(1, 1, 2, 'INSERT', 'products', 2, NULL, '{"name":"bariis","price":10,"stock":10}', '2026-03-02 21:04:04'),
(2, 1, 2, 'INSERT', 'products', 3, NULL, '{"name":"baasto","price":10,"stock":10}', '2026-03-02 21:04:24'),
(3, 2, 3, 'INSERT', 'products', 4, NULL, '{"name":"Buskud","sku":"SKU-1772485695459","price":0.5,"stock":100}', '2026-03-02 21:08:15'),
(4, 2, 3, 'INSERT', 'sales', 1, NULL, '{"customer_id":3,"items":[{"product_id":4,"quantity":10,"price":0.5}],"payment_status":"credit","paid_amount":0}', '2026-03-02 21:08:15'),
(5, 1, 2, 'INSERT', 'sales', 2, NULL, '{"customer_id":null,"payment_status":"paid","paid_amount":40,"items":[{"product_id":3,"quantity":3,"price":10},{"product_id":1,"quantity":1,"price":10}]}', '2026-03-06 12:10:38'),
(6, 1, 2, 'UPDATE', 'products', 3, NULL, '{"name":"baasto","sku":"","price":10,"stock":7}', '2026-03-06 13:04:50'),
(7, 1, 2, 'UPDATE', 'products', 2, NULL, '{"name":"bariis","sku":"","price":10,"stock":12}', '2026-03-06 13:05:27'),
(8, 1, 2, 'INSERT', 'sales', 3, NULL, '{"customer_id":1,"payment_status":"credit","paid_amount":0,"items":[{"product_id":3,"quantity":1,"price":10}]}', '2026-03-06 13:09:20')
ON CONFLICT (id) DO NOTHING;

SELECT setval('audit_logs_id_seq', COALESCE((SELECT MAX(id)+1 FROM audit_logs), 1), false);

-- DONE
