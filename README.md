# BookSafe Backend (CodeIgniter 4)

REST API for the BookSafe ERP, fully ported from the previous Node.js / Express + Sequelize stack to **CodeIgniter 4** (PHP 8.1+) and **MySQL / MariaDB**.

The mobile (Flutter) application consumes this API; **all endpoint paths, request bodies, query parameters and JSON response shapes are 100% identical** to the previous backend — the Flutter app does not need to change.

---

## Requirements

- PHP **8.1+** with extensions: `intl`, `mbstring`, `mysqlnd`, `curl`, `json`, `xml`
- **MySQL 5.7+ / MariaDB 10.4+**
- **Composer 2+**
- (Optional) Apache / Nginx (or `php spark serve` for local dev)

---

## Installation

```bash
cd backend

# 1) Install dependencies (CodeIgniter 4 framework + firebase/php-jwt)
composer install

# 2) Configure environment
cp .env.example .env
# Then open .env and update database credentials + jwt.secret

# 3) Create the database (e.g. via phpMyAdmin) named "booksafe_db"

# 4) Run migrations (creates all tables)
php spark migrate

# 5) Seed reference data
php spark db:seed UnitSeeder       # measurement units (kg, pcs, ...)
php spark db:seed ItAdminSeeder    # initial IT admin user

# 6) Start the dev server
php spark serve --host 0.0.0.0 --port 5000
```

The API is now available at `http://localhost:5000/api/...`.

Default IT-admin credentials (change immediately in production):

```
email:    admin@booksafe.com
password: adminpassword123
```

---

## Endpoint Overview

| Method | Path | Auth |
|---|---|---|
| POST   | `/api/auth/register-tenant`               | public |
| POST   | `/api/auth/login`                         | public |
| GET    | `/api/admin/tenants`                      | it_admin |
| GET    | `/api/admin/tenants/{id}`                 | it_admin |
| PUT    | `/api/admin/tenants/{id}/status`          | it_admin |
| POST   | `/api/admin/tenants/{id}/impersonate`     | it_admin |
| GET    | `/api/users`                              | tenant_admin |
| POST   | `/api/users`                              | tenant_admin |
| PUT    | `/api/users/{id}`                         | tenant_admin |
| GET    | `/api/branches`                           | tenant_admin / branch_manager / cashier |
| POST   | `/api/branches`                           | tenant_admin |
| PUT    | `/api/branches/{id}`                      | tenant_admin |
| GET    | `/api/products`                           | authenticated |
| POST   | `/api/products`                           | tenant_admin / branch_manager / cashier |
| PUT    | `/api/products/{id}`                      | tenant_admin / branch_manager |
| DELETE | `/api/products/{id}`                      | tenant_admin / branch_manager |
| GET    | `/api/customers`                          | authenticated |
| GET    | `/api/customers/debtors`                  | authenticated |
| GET    | `/api/customers/{id}`                     | authenticated |
| GET    | `/api/customers/{id}/history`             | authenticated |
| POST   | `/api/customers`                          | authenticated |
| PUT    | `/api/customers/{id}`                     | tenant_admin / branch_manager |
| DELETE | `/api/customers/{id}`                     | tenant_admin / branch_manager |
| GET    | `/api/sales`                              | authenticated |
| POST   | `/api/sales`                              | authenticated |
| GET    | `/api/payments`                           | authenticated |
| POST   | `/api/payments`                           | authenticated |
| GET    | `/api/finance`                            | tenant_admin / branch_manager |
| GET    | `/api/finance/summary`                    | tenant_admin / branch_manager |
| GET    | `/api/reports/sales`                      | tenant_admin / branch_manager |
| GET    | `/api/reports/top-products`               | tenant_admin / branch_manager |
| GET    | `/api/reports/debtors`                    | tenant_admin / branch_manager |
| GET    | `/api/reports/daily-sales`                | tenant_admin / branch_manager |
| GET    | `/api/reports/export-csv`                 | tenant_admin / branch_manager |
| GET    | `/api/units`                              | authenticated |

Authenticated endpoints expect a header:

```
Authorization: Bearer <token>
```

---

## Cron / Background Jobs

The daily "expired subscriptions" check is exposed as a Spark command:

```bash
php spark subscriptions:check
```

Schedule it with cron (00:00 EAT) on the server:

```cron
0 0 * * *  cd /var/www/booksafe/backend && /usr/bin/php spark subscriptions:check >> writable/logs/cron.log 2>&1
```

---

## Project Layout

```
backend/
├── app/
│   ├── Commands/                # CLI commands (cron jobs etc.)
│   ├── Config/                  # CI4 framework + app config
│   ├── Controllers/
│   │   └── Api/                 # All REST controllers
│   ├── Database/
│   │   ├── Migrations/          # Schema migrations
│   │   └── Seeds/               # Seed data
│   ├── Filters/                 # Auth / role / CORS filters
│   ├── Helpers/                 # Helper functions
│   ├── Libraries/               # JwtService etc.
│   └── Models/                  # Active Record models
├── public/
│   ├── index.php                # Front controller
│   └── .htaccess
├── writable/                    # Logs, cache, sessions
├── composer.json
├── spark                        # CI4 CLI entry point
└── .env.example
```

---

## Finance ledger

Every sale and debt payment is automatically written to the `finance` table — a single ledger that the rest of the system reads from for cash-flow / receivables reporting.

| Event                                | `transaction_type` | `cash_in` | `debt_added` | `debt_collected` |
|--------------------------------------|--------------------|-----------|--------------|------------------|
| Cash sale (paid in full)             | `sale_cash`        | total     | 0            | 0                |
| Credit sale (nothing paid)           | `sale_credit`      | 0         | total        | 0                |
| Partial-credit sale (some paid)      | `sale_partial`     | paid      | remaining    | 0                |
| Debt payment received                | `debt_payment`     | amount    | 0            | amount           |

The writes happen inside the same DB transaction as the underlying sale / payment, so the ledger is guaranteed to stay consistent (no partial state on failure). Queryable via:

```
GET /api/finance              # filterable list  (?type, ?from, ?to, ?customer_id, ?limit, ?offset)
GET /api/finance/summary      # totals: cash_in, cash_out, debt_added, debt_collected, net_cash, outstanding_debt, total_revenue
```

---

## Notes for the Mobile App

The mobile (Flutter) `ApiService` continues to point at the same `baseUrl` (`http(s)://host:port/api`). After deploying this CI4 backend, **no code change is required in the Flutter app** beyond verifying the host URL.
