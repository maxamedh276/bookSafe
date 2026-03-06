import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  final double price; // price used for this sale line

  CartItem({
    required this.product,
    this.quantity = 1,
    double? price,
  }) : price = price ?? product.price;

  double get total => price * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      final newState = List<CartItem>.from(state);
      newState[existingIndex].quantity++;
      state = newState;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(product: item.product, quantity: quantity)
        else
          item,
    ];
  }

  /// Update unit price for a specific cart line (e.g. discount or custom price).
  void updatePrice(int productId, double price) {
    if (price <= 0) return;
    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            price: price,
          )
        else
          item,
    ];
  }

  void clear() => state = [];

  double get totalAmount => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
