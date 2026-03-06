import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final tenantsProvider = FutureProvider<List<Tenant>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/admin/tenants');
  final List data = response.data;
  return data.map((json) => Tenant.fromJson(json)).toList();
});

class AdminNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  AdminNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> updateTenantStatus(int id, String status, {DateTime? expiryDate, int? branchLimit}) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/admin/tenants/$id/status', data: {
        'status': status,
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
        if (branchLimit != null) 'branch_limit': branchLimit,
      });
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> impersonate(int id, WidgetRef ref) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/admin/tenants/$id/impersonate');
      final data = response.data;
      
      await ref.read(authProvider.notifier).setImpersonation(data);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AsyncValue<void>>((ref) {
  return AdminNotifier(ref.watch(apiServiceProvider));
});
