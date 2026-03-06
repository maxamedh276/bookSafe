const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function runTest() {
    console.log('🚀 Bilaabaya tijaabada nidaamka (E2E API Test)...');

    try {
        // 1. Diiwaangelinta Tenant Cusub
        console.log('\n1. Is-diiwaangelinta Tenant Cusub...');
        const regRes = await axios.post(`${BASE_URL}/auth/register-tenant`, {
            business_name: 'Imtixaan Shop',
            owner_name: 'Axmed Cali',
            email: `test_${Date.now()}@imtixaan.com`,
            phone: '615123456',
            address: 'Maka Al Mukarama, Mogadishu',
            subscription_plan: 'basic',
            password: 'password123'
        });
        console.log('✅ Diiwaangelintu waa guul!');
        const tenantId = regRes.data.tenant.id;
        const testEmail = regRes.data.tenant.email;

        // 2. Login as IT Admin
        console.log('\n2. Login as IT Admin...');
        const adminLoginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'admin@booksafe.com',
            password: 'adminpassword123'
        });
        const adminToken = adminLoginRes.data.token;
        console.log('✅ Admin Login-ku waa guul!');

        // 3. Approve the Tenant
        console.log('\n3. Approving the new Tenant...');
        await axios.put(`${BASE_URL}/admin/tenants/${tenantId}/status`, {
            status: 'active',
            expiry_date: '2027-01-01'
        }, { headers: { Authorization: `Bearer ${adminToken}` } });
        console.log('✅ Tenant-ka waa la "Active" gareeyey!');

        // 4. Login as the new Tenant
        console.log('\n4. Galitaanka Nidaamka (Tenant Login)...');
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: testEmail,
            password: 'password123'
        });
        const token = loginRes.data.token;
        console.log('✅ Tenant Login-ku waa guul!');

        const authHeaders = { headers: { Authorization: `Bearer ${token}` } };

        // 5. Kudar Alaab (Product)
        console.log('\n5. Ku darista Alaab (Product)...');
        const productRes = await axios.post(`${BASE_URL}/products`, {
            name: 'Buskud',
            sku: `SKU-${Date.now()}`,
            price: 0.5,
            stock: 100
        }, authHeaders);
        const productId = productRes.data.id;
        console.log(`✅ Alaabta "${productRes.data.name}" waa lagu daray!`);

        // 6. Kudar Macmiil (Customer)
        console.log('\n6. Ku darista Macmiil (Customer)...');
        const customerRes = await axios.post(`${BASE_URL}/customers`, {
            name: 'Jaamac Faarax',
            phone: '615001122',
            email: 'jaamac@test.com'
        }, authHeaders);
        const customerId = customerRes.data.id;
        console.log(`✅ Macmiilka "${customerRes.data.name}" waa lagu daray!`);

        // 7. Samee Iib (Sale) - Deyn ahaan
        console.log('\n7. Sameynta Iib (Sale) - Deyn ahaan...');
        const saleRes = await axios.post(`${BASE_URL}/sales`, {
            customer_id: customerId,
            items: [
                { product_id: productId, quantity: 10, price: 0.5 }
            ],
            payment_status: 'credit',
            paid_amount: 0
        }, authHeaders);
        console.log(`✅ Iibka ${saleRes.data.invoice_number} waa lagu guulaystay! Deyn: $${saleRes.data.debt_amount}`);

        // 8. Hubi Warbixinta (Report)
        console.log('\n8. Hubinta Warbixinada (Reports)...');
        const reportRes = await axios.get(`${BASE_URL}/reports/sales`, authHeaders);
        console.log(`✅ Warbixinta: Total Sales: $${reportRes.data.totalSales}, Total Debt: $${reportRes.data.totalDebt}`);

        console.log('\n✨ TIJAABADU WAA DHAMMAATAY: Nidaamku wuu wada shaqaynayaa!');

    } catch (error) {
        console.error('\n❌ TIJAABADU WAA FASHILANTAY:');
        if (error.response) {
            console.error('Error Data:', error.response.data);
        } else {
            console.error('Error Message:', error.message);
        }
    }
}

runTest();
