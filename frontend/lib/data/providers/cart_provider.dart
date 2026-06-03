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

  void addToCart(Product product, {int quantity = 1}) {
    final qty = quantity < 1 ? 1 : quantity;
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      final newState = List<CartItem>.from(state);
      newState[existingIndex].quantity += qty;
      state = newState;
    } else {
      state = [...state, CartItem(product: product, quantity: qty)];
    }
  }

  /// Add [amount] to current line quantity (used when user enters bulk qty then taps +).
  void incrementQuantityBy(int productId, int amount) {
    final add = amount < 1 ? 1 : amount;
    final index = state.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;
    updateQuantity(productId, state[index].quantity + add);
  }

  /// Subtract [amount] from current line quantity (min 0 removes line).
  void decrementQuantityBy(int productId, int amount) {
    final sub = amount < 1 ? 1 : amount;
    final index = state.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;
    updateQuantity(productId, state[index].quantity - sub);
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
