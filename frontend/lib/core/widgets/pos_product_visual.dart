import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';

/// Icon + gradient theme inferred from product name, category, and unit.
class PosProductVisual {
  final IconData icon;
  final List<Color> gradient;
  final Color accent;

  const PosProductVisual({
    required this.icon,
    required this.gradient,
    required this.accent,
  });
}

bool _containsAny(String haystack, List<String> keys) {
  for (final key in keys) {
    if (haystack.contains(key)) return true;
  }
  return false;
}

PosProductVisual resolveProductVisual(Product product) {
  final haystack = [
    product.name,
    product.category ?? '',
    product.unitFullName ?? '',
    product.unitName ?? '',
  ].join(' ').toLowerCase();

  if (_containsAny(haystack, ['bariis', 'rice', 'canjeero', 'baasto', 'pasta', 'noodle'])) {
    return const PosProductVisual(
      icon: Icons.rice_bowl_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      accent: Color(0xFFD97706),
    );
  }
  if (_containsAny(haystack, ['subag', 'saliid', 'oil', 'butter', 'margarine'])) {
    return const PosProductVisual(
      icon: Icons.water_drop_rounded,
      gradient: [Color(0xFFF97316), Color(0xFFFDBA74)],
      accent: Color(0xFFEA580C),
    );
  }
  if (_containsAny(haystack, ['sonkor', 'sugar', 'macmacaan', 'candy', 'chocolate'])) {
    return const PosProductVisual(
      icon: Icons.cookie_rounded,
      gradient: [Color(0xFFEC4899), Color(0xFFF472B6)],
      accent: Color(0xFFDB2777),
    );
  }
  if (_containsAny(haystack, ['caano', 'milk', 'yogurt', 'cheese', 'jibbaar'])) {
    return const PosProductVisual(
      icon: Icons.local_drink_rounded,
      gradient: [Color(0xFF38BDF8), Color(0xFF7DD3FC)],
      accent: Color(0xFF0284C7),
    );
  }
  if (_containsAny(haystack, ['hilib', 'meat', 'digaag', 'chicken', 'goat', 'ari', 'beef'])) {
    return const PosProductVisual(
      icon: Icons.set_meal_rounded,
      gradient: [Color(0xFFEF4444), Color(0xFFF87171)],
      accent: Color(0xFFDC2626),
    );
  }
  if (_containsAny(haystack, ['kalluun', 'fish', 'seafood'])) {
    return const PosProductVisual(
      icon: Icons.phishing_rounded,
      gradient: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
      accent: Color(0xFF0891B2),
    );
  }
  if (_containsAny(haystack, ['khudaar', 'vegetable', 'salad', 'carrot', 'tomato', 'basal', 'onion', 'potato', 'baradho'])) {
    return const PosProductVisual(
      icon: Icons.eco_rounded,
      gradient: [Color(0xFF22C55E), Color(0xFF86EFAC)],
      accent: Color(0xFF16A34A),
    );
  }
  if (_containsAny(haystack, ['miraha', 'fruit', 'apple', 'banana', 'orange', 'moos', 'tufaax'])) {
    return const PosProductVisual(
      icon: Icons.emoji_food_beverage_rounded,
      gradient: [Color(0xFF84CC16), Color(0xFFBEF264)],
      accent: Color(0xFF65A30D),
    );
  }
  if (_containsAny(haystack, ['rooti', 'bread', 'bakery', 'cake', 'buskud', 'biscuit'])) {
    return const PosProductVisual(
      icon: Icons.bakery_dining_rounded,
      gradient: [Color(0xFFD97706), Color(0xFFFCD34D)],
      accent: Color(0xFFB45309),
    );
  }
  if (_containsAny(haystack, ['shaah', 'tea', 'coffee', 'bun', 'cabitaan', 'juice', 'soda', 'biyo'])) {
    return const PosProductVisual(
      icon: Icons.local_cafe_rounded,
      gradient: [Color(0xFF78716C), Color(0xFFA8A29E)],
      accent: Color(0xFF57534E),
    );
  }
  if (_containsAny(haystack, ['saabuun', 'soap', 'shampoo', 'detergent', 'nadiif', 'clean'])) {
    return const PosProductVisual(
      icon: Icons.soap_rounded,
      gradient: [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
      accent: Color(0xFF7C3AED),
    );
  }
  if (_containsAny(haystack, ['daawo', 'medicine', 'pharma', 'tablet', 'panadol'])) {
    return const PosProductVisual(
      icon: Icons.medical_services_rounded,
      gradient: [Color(0xFF3B82F6), Color(0xFF93C5FD)],
      accent: Color(0xFF2563EB),
    );
  }
  if (_containsAny(haystack, ['dhar', 'cloth', 'shirt', 'shoes', 'kab', 'fashion'])) {
    return const PosProductVisual(
      icon: Icons.checkroom_rounded,
      gradient: [Color(0xFFA855F7), Color(0xFFD8B4FE)],
      accent: Color(0xFF9333EA),
    );
  }
  if (_containsAny(haystack, ['buug', 'book', 'qalin', 'pen', 'stationery'])) {
    return const PosProductVisual(
      icon: Icons.menu_book_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
      accent: Color(0xFF4F46E5),
    );
  }
  if (_containsAny(haystack, ['shidaal', 'fuel', 'petrol', 'gas', 'diesel'])) {
    return const PosProductVisual(
      icon: Icons.local_gas_station_rounded,
      gradient: [Color(0xFF64748B), Color(0xFF94A3B8)],
      accent: Color(0xFF475569),
    );
  }

  switch (product.unitName) {
    case 'kg':
    case 'g':
    case 'qkg':
    case 'sack':
    case 'bag':
      return const PosProductVisual(
        icon: Icons.scale_rounded,
        gradient: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
        accent: Color(0xFF0D9488),
      );
    case 'l':
    case 'ml':
      return const PosProductVisual(
        icon: Icons.water_drop_rounded,
        gradient: [Color(0xFF0EA5E9), Color(0xFF7DD3FC)],
        accent: Color(0xFF0284C7),
      );
    case 'thm':
      return const PosProductVisual(
        icon: Icons.back_hand_rounded,
        gradient: [Color(0xFFF59E0B), Color(0xFFFDE68A)],
        accent: Color(0xFFD97706),
      );
    case 'box':
    case 'ctn':
    case 'pack':
      return const PosProductVisual(
        icon: Icons.inventory_2_rounded,
        gradient: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
        accent: Color(0xFF4F46E5),
      );
    default:
      return const PosProductVisual(
        icon: Icons.shopping_bag_rounded,
        gradient: [Color(0xFF0D9488), Color(0xFF14B8A6)],
        accent: Color(0xFF0D9488),
      );
  }
}
