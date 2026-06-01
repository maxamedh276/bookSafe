import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/services/api_service.dart';
import 'package:intl/intl.dart';

class TenantsListView extends ConsumerWidget {
  const TenantsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maamulka Ganacsiyada',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Approve, edit, ama arag ganacsiyada diiwaangashan.',
              style: TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: tenantsAsync.when(
                data: (tenants) {
                  if (tenants.isEmpty) {
                    return const Center(child: Text('Ma jiraan ganacsiyo diiwaangashan.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(tenantsProvider),
                    child: ListView.separated(
                      itemCount: tenants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _TenantCard(tenant: tenants[index]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 8),
                      Text('Khalad: $e', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(tenantsProvider),
                        child: const Text('Isku day mar kale'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantCard extends ConsumerWidget {
  final Tenant tenant;
  const _TenantCard({required this.tenant});

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminProvider.notifier).updateTenantStatus(
            tenant.id,
            'active',
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            branchLimit: tenant.branchLimit > 0 ? tenant.branchLimit : 1,
          );
      ref.invalidate(tenantsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tenant.businessName} waa la approve gareeyey!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = ref.read(apiServiceProvider).getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => UpdateStatusDialog(tenant: tenant),
    ).then((value) {
      if (value == true) ref.invalidate(tenantsProvider);
    });
  }

  Future<void> _impersonate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminProvider.notifier).impersonate(tenant.id, ref);
      if (context.mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hadda waxaad u muuqataa sidii ${tenant.businessName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = ref.read(apiServiceProvider).getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = tenant.status;
    final isPending = status == 'pending';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.ownerName,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                      Text(
                        tenant.email,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.card_membership,
                  label: tenant.subscriptionPlan.toUpperCase(),
                  color: Colors.blue,
                ),
                _InfoChip(
                  icon: Icons.store,
                  label: 'Branches: ${tenant.branchLimit}',
                  color: Colors.purple,
                ),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: tenant.expiryDate != null
                      ? DateFormat('dd/MM/yyyy').format(tenant.expiryDate!)
                      : 'Expiry: -',
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions — always visible
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isPending)
                  ElevatedButton.icon(
                    onPressed: () => _approve(context, ref),
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _showUpdateDialog(context, ref),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                if (!isPending)
                  OutlinedButton.icon(
                    onPressed: () => _impersonate(context, ref),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View as Tenant'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'blocked':
      case 'suspended':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class UpdateStatusDialog extends ConsumerStatefulWidget {
  final Tenant tenant;
  const UpdateStatusDialog({super.key, required this.tenant});

  @override
  ConsumerState<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends ConsumerState<UpdateStatusDialog> {
  late String _status;
  late int _branchLimit;
  DateTime? _expiryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.tenant.status;
    _branchLimit = widget.tenant.branchLimit;
    _expiryDate = widget.tenant.expiryDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update ${widget.tenant.businessName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['pending', 'active', 'suspended', 'blocked']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _branchLimit.toString(),
              decoration: const InputDecoration(labelText: 'Branch Limit'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _branchLimit = int.tryParse(v) ?? _branchLimit,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date'),
              subtitle: Text(
                _expiryDate == null
                    ? 'Madihin'
                    : DateFormat('dd/MM/yyyy').format(_expiryDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await ref.read(adminProvider.notifier).updateTenantStatus(
                          widget.tenant.id,
                          _status,
                          expiryDate: _expiryDate,
                          branchLimit: _branchLimit,
                        );
                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      final msg = ref.read(apiServiceProvider).getErrorMessage(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Update'),
        ),
      ],
    );
  }
}
