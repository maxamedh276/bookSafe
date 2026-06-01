import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/unit_provider.dart';
import '../theme/app_colors.dart';

/// Reusable unit selector for inventory & POS forms.
class UnitDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool allowNone;

  const UnitDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowNone = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);

    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Unugga (Unit)',
              border: OutlineInputBorder(),
            ),
            child: Text(
              'Units lama helin. Fadlan seed-garee backend-ka.',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          );
        }

        return DropdownButtonFormField<int?>(
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: const InputDecoration(
            labelText: 'Unugga (Unit)',
            border: OutlineInputBorder(),
          ),
          value: units.any((u) => u.id == value) ? value : null,
          items: [
            if (allowNone)
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Dhib malahan (None)'),
              ),
            ...units.map(
              (u) => DropdownMenuItem<int?>(
                value: u.id,
                child: Text(u.displayLabel, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Unugga (Unit)',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Soo raraya units...', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      error: (e, _) => InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Unugga (Unit)',
          border: OutlineInputBorder(),
          errorText: 'Units lama soo rari karin',
        ),
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppColors.error, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
