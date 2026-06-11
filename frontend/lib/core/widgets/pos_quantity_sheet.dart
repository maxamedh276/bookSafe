import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../utils/unit_utils.dart';
import 'quantity_select_field.dart';

/// Bottom sheet for choosing quantity before adding to POS cart.
Future<double?> showPosQuantitySheet(BuildContext context, Product product) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PosQuantitySheet(product: product),
  );
}

class _PosQuantitySheet extends StatefulWidget {
  final Product product;

  const _PosQuantitySheet({required this.product});

  @override
  State<_PosQuantitySheet> createState() => _PosQuantitySheetState();
}

class _PosQuantitySheetState extends State<_PosQuantitySheet> {
  late double _selectedQty;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    _selectedQty = defaultQuantityForUnit(product.unitName);
  }

  double get _lineTotal => product.price * _selectedQty;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPricePerUnit(product.price, product.unitName),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Unug: ${formatUnitBadge(product.unitName, unitFullName: product.unitFullName)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Stock: ${formatStock(product.stock, product.unitName)}',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                QuantitySelectField(
                  value: _selectedQty,
                  unitShortName: product.unitName,
                  label: 'Dooro tirada — ${formatUnitBadge(product.unitName, unitFullName: product.unitFullName)}',
                  onChanged: (qty) => setState(() => _selectedQty = qty),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        formatQuantityBilingual(_selectedQty, product.unitName),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '× ${formatPricePerUnit(product.price, product.unitName)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Wadarta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(
                            '\$${_lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                        child: const Text('Jooji'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _selectedQty <= 0
                            ? null
                            : () {
                                if (_selectedQty > product.stock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Stock kuma filna. Hadda: ${formatStock(product.stock, product.unitName)}',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context, _selectedQty);
                              },
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Ku dar Cart-ka', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
