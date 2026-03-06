const AuditLog = require('../models/AuditLog');

/**
 * auditMiddleware – Automatically logs all data-changing API calls.
 *
 * Usage in a route:
 *   router.post('/products', protect, auditLog('products'), createProduct);
 *
 * The middleware captures action, table name, record id, and user from context.
 * It runs AFTER the controller responds, using a response interceptor.
 */
const auditLog = (tableName) => {
    return (req, res, next) => {
        const originalJson = res.json.bind(res);

        res.json = async (data) => {
            // Only log mutations (POST, PUT, PATCH, DELETE)
            const mutatingMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
            if (mutatingMethods.includes(req.method) && req.user) {
                const actionMap = {
                    POST: 'INSERT',
                    PUT: 'UPDATE',
                    PATCH: 'UPDATE',
                    DELETE: 'DELETE',
                };

                try {
                    await AuditLog.create({
                        tenant_id: req.user.tenant_id || null,
                        user_id: req.user.id,
                        action: actionMap[req.method],
                        table_name: tableName,
                        record_id: data?.id || data?.[tableName.slice(0, -1)]?.id || null,
                        old_value: null,
                        new_value: req.body ? JSON.stringify(req.body).substring(0, 1000) : null,
                    });
                } catch (auditError) {
                    // Never block the response because of audit failure
                    console.error('[AuditLog] Failed to write audit log:', auditError.message);
                }
            }

            return originalJson(data);
        };

        next();
    };
};

module.exports = { auditLog };
