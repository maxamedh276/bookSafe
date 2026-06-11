// Helpers for POS fractional units (kg, thumun, pcs, etc.).

class QuantityOption {
  final double value;
  final String somaliLabel;
  final String numericLabel;

  const QuantityOption({
    required this.value,
    required this.somaliLabel,
    required this.numericLabel,
  });

  String get displayText => '$somaliLabel  •  $numericLabel';

  bool matches(double qty) => (value - qty).abs() < 0.0001;
}

typedef QuantityPreset = QuantityOption;

const _customOptionValue = -1.0;

double get quantityCustomMarker => _customOptionValue;

bool isCustomQuantityMarker(double? value) =>
    value != null && (value - _customOptionValue).abs() < 0.0001;

/// Canonical short codes used across POS + inventory.
const _aliasToShort = {
  'kilogram': 'kg',
  'kilo': 'kg',
  'gram': 'g',
  'milligram': 'mg',
  'liter': 'l',
  'litre': 'l',
  'litir': 'l',
  'milliliter': 'ml',
  'millilitre': 'ml',
  'piece': 'pcs',
  'pieces': 'pcs',
  'xabbo': 'pcs',
  'xabo': 'pcs',
  'handful': 'thm',
  'thumun': 'thm',
  'thum': 'thm',
  'quarter kilo': 'qkg',
  'rubac kilo': 'qkg',
  'rubac': 'qkg',
  'dozen': 'dz',
  'box': 'box',
  'bottle': 'btl',
  'can': 'can',
  'carton': 'ctn',
  'pack': 'pack',
  'pair': 'pair',
  'roll': 'roll',
  'bag': 'bag',
  'sack': 'sack',
  'bucket': 'bkt',
  'meter': 'm',
  'metre': 'm',
  'centimeter': 'cm',
  'centimetre': 'cm',
  'feet': 'ft',
  'foot': 'ft',
  'inch': 'in',
  'set': 'set',
};

const _weightUnits = {'kg', 'g', 'mg', 'lb', 'oz', 'sack', 'bag', 'qkg'};
const _volumeUnits = {'l', 'ml'};
const _handfulUnits = {'thm'};
const _linearUnits = {'m', 'cm', 'ft', 'in'};
const _countUnits = {'pcs', 'box', 'dz', 'pack', 'set', 'btl', 'can', 'ctn', 'pair', 'roll', 'bkt'};

/// Thumun ≈ 150g — caadi dukaamada Soomaalida.
const double thumunInKg = 0.15;

/// Normalize API / legacy values to a short unit code (kg, pcs, thm, ...).
String normalizeUnitShortName(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'pcs';
  final lower = raw.trim().toLowerCase();
  if (_aliasToShort.containsKey(lower)) return _aliasToShort[lower]!;
  if (_isKnownShort(lower)) return lower;
  return lower;
}

bool _isKnownShort(String code) =>
    _weightUnits.contains(code) ||
    _volumeUnits.contains(code) ||
    _handfulUnits.contains(code) ||
    _linearUnits.contains(code) ||
    _countUnits.contains(code);

enum UnitCategory { weight, volume, handful, linear, count, unknown }

UnitCategory unitCategory(String? unitShortName) {
  final u = normalizeUnitShortName(unitShortName);
  if (_weightUnits.contains(u)) return UnitCategory.weight;
  if (_volumeUnits.contains(u)) return UnitCategory.volume;
  if (_handfulUnits.contains(u)) return UnitCategory.handful;
  if (_linearUnits.contains(u)) return UnitCategory.linear;
  if (_countUnits.contains(u)) return UnitCategory.count;
  return UnitCategory.unknown;
}

bool unitAllowsFraction(String? unitShortName) {
  final cat = unitCategory(unitShortName);
  return cat == UnitCategory.weight ||
      cat == UnitCategory.volume ||
      cat == UnitCategory.linear ||
      cat == UnitCategory.unknown && normalizeUnitShortName(unitShortName) != 'pcs';
}

/// Somali word for the selling unit (shown in labels).
String unitSomaliName(String? unitShortName) {
  switch (normalizeUnitShortName(unitShortName)) {
    case 'kg':
    case 'qkg':
    case 'sack':
    case 'bag':
      return 'kilo';
    case 'g':
      return 'gram';
    case 'l':
      return 'litir';
    case 'ml':
      return 'ml';
    case 'thm':
      return 'thumun';
    case 'm':
      return 'mitir';
    case 'cm':
      return 'sentimitir';
    case 'box':
      return 'sanduuq';
    case 'dz':
      return 'dozen';
    case 'btl':
      return 'dhalada';
    case 'can':
      return 'kaan';
    case 'ctn':
      return 'kartoon';
    case 'pack':
      return 'baak';
    case 'pair':
      return 'labo';
    case 'roll':
      return 'duub';
    case 'bkt':
      return 'baket';
    case 'pcs':
    default:
      return 'xabbo';
  }
}

String _fmtNum(double value) {
  if ((value - value.roundToDouble()).abs() < 0.0001) return value.round().toString();
  return value.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

QuantityOption _opt(double value, String somali, String unitCode) => QuantityOption(
      value: value,
      somaliLabel: somali,
      numericLabel: '${_fmtNum(value)} $unitCode',
    );

List<QuantityOption> _weightOptions(String unitCode) {
  final u = normalizeUnitShortName(unitCode);
  return [
    if (u == 'kg' || u == 'sack' || u == 'bag' || u == 'qkg') ...[
      _opt(0.15, 'Hal thumun', u),
      _opt(0.25, 'Rubac', u),
      _opt(0.5, 'Nus kilo', u),
      _opt(0.75, 'Saddex-meelood', u),
    ] else ...[
      _opt(0.25, 'Rubac', u),
      _opt(0.5, 'Nus', u),
    ],
    _opt(1, u == 'g' ? 'Hal kilo' : 'Hal ${unitSomaliName(u)}', u),
    _opt(2, 'Laba ${unitSomaliName(u)}', u),
    _opt(5, 'Shan ${unitSomaliName(u)}', u),
  ];
}

List<QuantityOption> _handfulOptions() => [
      _opt(1, 'Hal thumun', 'thm'),
      _opt(2, 'Laba thumun', 'thm'),
      _opt(3, 'Saddex thumun', 'thm'),
      _opt(5, 'Shan thumun', 'thm'),
      _opt(10, 'Toban thumun', 'thm'),
    ];

List<QuantityOption> _volumeOptions(String unitCode) {
  final u = normalizeUnitShortName(unitCode);
  if (u == 'ml') {
    return [
      _opt(250, 'Rubac litir', 'ml'),
      _opt(500, 'Nus litir', 'ml'),
      _opt(1000, 'Hal litir', 'ml'),
      _opt(2000, 'Laba litir', 'ml'),
    ];
  }
  return [
    _opt(0.25, 'Rubac', 'l'),
    _opt(0.5, 'Nus litir', 'l'),
    _opt(1, 'Hal litir', 'l'),
    _opt(2, 'Laba litir', 'l'),
  ];
}

List<QuantityOption> _countOptions(String unitCode) {
  final u = normalizeUnitShortName(unitCode);
  final word = unitSomaliName(u);
  return [
    _opt(1, 'Hal $word', u),
    _opt(2, 'Laba $word', u),
    _opt(3, 'Saddex $word', u),
    _opt(5, 'Shan $word', u),
    _opt(10, 'Toban $word', u),
    _opt(12, 'Lix iyo lix $word', u),
  ];
}

List<QuantityOption> _linearOptions(String unitCode) {
  final u = normalizeUnitShortName(unitCode);
  return [
    _opt(0.25, 'Rubac', u),
    _opt(0.5, 'Nus', u),
    _opt(1, 'Hal ${unitSomaliName(u)}', u),
    _opt(2, 'Laba ${unitSomaliName(u)}', u),
  ];
}

/// POS quantity choices — waxay ku xiran yihiin unugga alaabta (kg, thm, pcs, ...).
List<QuantityOption> quantityOptionsForUnit(String? unitShortName) {
  if (unitShortName == null || unitShortName.trim().isEmpty) return const [];

  final u = normalizeUnitShortName(unitShortName);
  switch (unitCategory(u)) {
    case UnitCategory.weight:
      return _weightOptions(u);
    case UnitCategory.handful:
      return _handfulOptions();
    case UnitCategory.volume:
      return _volumeOptions(u);
    case UnitCategory.linear:
      return _linearOptions(u);
    case UnitCategory.count:
      return _countOptions(u);
    case UnitCategory.unknown:
      return _countOptions(u);
  }
}

List<QuantityOption> quantityPresetsForUnit(String? unitShortName) =>
    quantityOptionsForUnit(unitShortName);

QuantityOption? findQuantityOption(double qty, List<QuantityOption> options) {
  for (final option in options) {
    if (option.matches(qty)) return option;
  }
  return null;
}

/// Default selection when opening POS sheet for a product.
double defaultQuantityForUnit(String? unitShortName) {
  final options = quantityOptionsForUnit(unitShortName);
  if (options.isEmpty) return 1;

  final cat = unitCategory(unitShortName);
  if (cat == UnitCategory.weight) {
    return findQuantityOption(0.5, options)?.value ??
        findQuantityOption(0.25, options)?.value ??
        options.first.value;
  }
  if (cat == UnitCategory.handful) return 1;
  return options.first.value;
}

double defaultQtyStep(String? unitShortName) {
  final cat = unitCategory(unitShortName);
  if (cat == UnitCategory.weight) return 0.25;
  if (cat == UnitCategory.volume && normalizeUnitShortName(unitShortName) == 'l') return 0.25;
  if (cat == UnitCategory.linear) return 0.25;
  return 1;
}

double parseQuantityInput(String raw) {
  final cleaned = raw.trim().replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0;
}

String formatQuantity(double qty, [String? unitShortName]) {
  final u = normalizeUnitShortName(unitShortName);
  final isWhole = (qty - qty.roundToDouble()).abs() < 0.0001;
  final text = isWhole
      ? qty.round().toString()
      : qty.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  if (unitShortName == null || unitShortName.trim().isEmpty) return text;
  return '$text $u';
}

String formatQuantityBilingual(double qty, String? unitShortName) {
  final options = quantityOptionsForUnit(unitShortName);
  final match = findQuantityOption(qty, options);
  if (match != null) return match.displayText;
  return formatQuantity(qty, unitShortName);
}

String formatPricePerUnit(double price, String? unitShortName) {
  final u = normalizeUnitShortName(unitShortName);
  if (unitShortName == null || unitShortName.trim().isEmpty) {
    return '\$${price.toStringAsFixed(2)}';
  }
  return '\$${price.toStringAsFixed(2)}/$u';
}

String formatStock(double stock, String? unitShortName) {
  return formatQuantity(stock, unitShortName);
}

/// Badge text: "Unug: kilo (kg)"
String formatUnitBadge(String? unitShortName, {String? unitFullName}) {
  if (unitShortName == null || unitShortName.trim().isEmpty) {
    return 'Unug ma la doorin';
  }
  final short = normalizeUnitShortName(unitShortName);
  final somali = unitSomaliName(short);
  if (unitFullName != null && unitFullName.trim().isNotEmpty) {
    return '$unitFullName ($short)';
  }
  return '$somali ($short)';
}
