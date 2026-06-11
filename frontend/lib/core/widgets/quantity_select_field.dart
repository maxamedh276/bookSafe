import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/unit_utils.dart';

/// Beautiful quantity dropdown: Somali label + numeric value side by side.
class QuantitySelectField extends StatefulWidget {
  final double value;
  final String? unitShortName;
  final ValueChanged<double> onChanged;
  final bool allowCustom;
  final bool compact;
  final String? label;

  const QuantitySelectField({
    super.key,
    required this.value,
    required this.onChanged,
    this.unitShortName,
    this.allowCustom = true,
    this.compact = false,
    this.label,
  });

  @override
  State<QuantitySelectField> createState() => _QuantitySelectFieldState();
}

class _QuantitySelectFieldState extends State<QuantitySelectField> {
  late final TextEditingController _customController;
  bool _showCustomField = false;

  List<QuantityOption> get _options => quantityOptionsForUnit(widget.unitShortName);

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: formatQuantity(widget.value, widget.unitShortName));
    _showCustomField =
        _options.isEmpty || findQuantityOption(widget.value, _options) == null;
  }

  @override
  void didUpdateWidget(covariant QuantitySelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final unitChanged = normalizeUnitShortName(oldWidget.unitShortName) !=
        normalizeUnitShortName(widget.unitShortName);
    if (unitChanged) {
      _showCustomField = findQuantityOption(widget.value, _options) == null;
      _customController.text = formatQuantity(widget.value, widget.unitShortName);
    } else if ((oldWidget.value - widget.value).abs() > 0.0001) {
      final match = findQuantityOption(widget.value, _options);
      _showCustomField = match == null;
      if (!_showCustomField || _customController.text.isEmpty) {
        _customController.text = formatQuantity(widget.value, widget.unitShortName);
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  double? get _dropdownValue {
    if (_options.isEmpty) {
      return widget.allowCustom ? quantityCustomMarker : null;
    }
    if (_showCustomField && widget.allowCustom) return quantityCustomMarker;
    final match = findQuantityOption(widget.value, _options);
    return match?.value ?? (widget.allowCustom ? quantityCustomMarker : _options.first.value);
  }

  void _onDropdownChanged(double? picked) {
    if (picked == null) return;
    if (isCustomQuantityMarker(picked)) {
      setState(() {
        _showCustomField = true;
        _customController.text = formatQuantity(widget.value, widget.unitShortName);
      });
      return;
    }
    setState(() => _showCustomField = false);
    widget.onChanged(picked);
  }

  void _applyCustom() {
    final parsed = parseQuantityInput(_customController.text);
    if (parsed > 0) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final unit = normalizeUnitShortName(widget.unitShortName);
    final unitBadge = formatUnitBadge(widget.unitShortName);
    final radius = BorderRadius.circular(widget.compact ? 10 : 14);
    final menuItems = <DropdownMenuItem<double>>[
      ..._options.map(
        (option) => DropdownMenuItem<double>(
          value: option.value,
          child: _QuantityOptionTile(option: option, compact: widget.compact),
        ),
      ),
      if (widget.allowCustom)
        DropdownMenuItem<double>(
          value: quantityCustomMarker,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: widget.compact ? 16 : 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tirada kale',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: widget.compact ? 12 : 14,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      'Geli tiro gaar ah',
                      style: TextStyle(fontSize: widget.compact ? 10 : 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_options.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: radius,
            ),
            child: const Text(
              'Alaabtan unug ma loo qorin. Inventory ka dooro unug (kg, thm, pcs).',
              style: TextStyle(fontSize: 12, color: AppColors.textHeading),
            ),
          ),
        if (_options.isNotEmpty)
          DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: radius,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<double>(
            isExpanded: true,
            value: _dropdownValue,
            menuMaxHeight: 360,
            decoration: InputDecoration(
              labelText: widget.label ?? 'Dooro tirada — $unitBadge',
              labelStyle: TextStyle(
                fontSize: widget.compact ? 11 : 13,
                color: AppColors.textLight,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 12 : 16,
                vertical: widget.compact ? 8 : 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.straighten_rounded,
                color: AppColors.primary,
                size: widget.compact ? 18 : 22,
              ),
            ),
            selectedItemBuilder: (context) {
              return menuItems.map((item) {
                if (isCustomQuantityMarker(item.value)) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatQuantityBilingual(widget.value, widget.unitShortName),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: widget.compact ? 12 : 14,
                        color: AppColors.textHeading,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                final option = _options.firstWhere((o) => o.matches(item.value!));
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    option.displayText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: widget.compact ? 12 : 14,
                      color: AppColors.textHeading,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            items: menuItems,
            onChanged: _onDropdownChanged,
            dropdownColor: Colors.white,
            borderRadius: radius,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          ),
        ),
        if (_options.isEmpty || (_showCustomField && widget.allowCustom)) ...[
          SizedBox(height: widget.compact ? 8 : 12),
          TextField(
            controller: _customController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.compact ? 14 : 16,
            ),
            decoration: InputDecoration(
              labelText: 'Tirada tiro ahaan ($unit)',
              hintText: unitAllowsFraction(widget.unitShortName)
                  ? 'Tusaale: 0.5 $unit'
                  : 'Tusaale: 3 $unit',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: radius),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle, color: AppColors.success),
                onPressed: _applyCustom,
                tooltip: 'Kaydi tirada',
              ),
            ),
            onSubmitted: (_) => _applyCustom(),
          ),
        ],
      ],
    );
  }
}

class _QuantityOptionTile extends StatelessWidget {
  final QuantityOption option;
  final bool compact;

  const _QuantityOptionTile({required this.option, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              option.numericLabel.split(' ').first,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.somaliLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  option.numericLabel,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
