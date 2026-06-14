import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../utils/unit_utils.dart';
import 'pos_product_visual.dart';

/// Responsive POS product grid: 4 → 3 → 2 columns.
class PosProductGrid {
  PosProductGrid._();

  static int crossAxisCount(double width) {
    if (width >= 1280) return 4;
    if (width >= 880) return 3;
    return 2;
  }

  static double childAspectRatio(double width) {
    final cols = crossAxisCount(width);
    if (cols >= 4) return 2.75;
    if (cols >= 3) return 2.55;
    return 2.35;
  }

  static SliverGridDelegate delegate(double width) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount(width),
      childAspectRatio: childAspectRatio(width),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    );
  }
}

/// Compact horizontal product chip — app teal theme, lightweight.
class PosProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PosProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<PosProductCard> createState() => _PosProductCardState();
}

class _PosProductCardState extends State<PosProductCard> {
  bool _pressed = false;

  Product get product => widget.product;

  @override
  Widget build(BuildContext context) {
    final visual = resolveProductVisual(product);
    final isLow = product.stock > 0 && product.stock < 5;
    final isOut = product.stock <= 0;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: _pressed ? 0.28 : 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _pressed ? 0.06 : 0.1),
                  blurRadius: _pressed ? 4 : 10,
                  offset: Offset(0, _pressed ? 2 : 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _ProductIconBadge(icon: visual.icon, pressed: _pressed),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.textHeading,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatPricePerUnit(product.price, product.unitName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _StockDot(isLow: isLow, isOut: isOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Same card for mobile list rows (alias).
class PosProductListCard extends PosProductCard {
  const PosProductListCard({
    super.key,
    required super.product,
    required super.onTap,
    super.onLongPress,
  });
}

class _ProductIconBadge extends StatelessWidget {
  final IconData icon;
  final bool pressed;

  const _ProductIconBadge({required this.icon, required this.pressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _StockDot extends StatelessWidget {
  final bool isLow;
  final bool isOut;

  const _StockDot({required this.isLow, required this.isOut});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isOut) {
      color = AppColors.error;
    } else if (isLow) {
      color = AppColors.warning;
    } else {
      color = AppColors.success;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
