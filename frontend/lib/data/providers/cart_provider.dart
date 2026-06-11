import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/product_model.dart';
import '../../core/utils/unit_utils.dart';

class CartItem {
  final Product product;
  double quantity;
  final double price;

  CartItem({
    required this.product,
    this.quantity = 1,
    double? price,
  }) : price = price ?? product.price;

  double get total => price * quantity;
  String get unitLabel => product.unitName ?? '';
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product, {double quantity = 1}) {
    final qty = quantity <= 0 ? 1.0 : quantity;
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      final newState = List<CartItem>.from(state);
      newState[existingIndex].quantity += qty;
      state = newState;
    } else {
      state = [...state, CartItem(product: product, quantity: qty)];
    }
  }

  void incrementQuantityBy(int productId, double amount) {
    final add = amount <= 0 ? 1.0 : amount;
    final index = state.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;
    updateQuantity(productId, state[index].quantity + add);
  }

  void decrementQuantityBy(int productId, double amount) {
    final sub = amount <= 0 ? 1.0 : amount;
    final index = state.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;
    updateQuantity(productId, state[index].quantity - sub);
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(product: item.product, quantity: quantity, price: item.price)
        else
          item,
    ];
  }

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

  double qtyStepFor(Product product) => defaultQtyStep(product.unitName);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
