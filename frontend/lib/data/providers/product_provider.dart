import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get('/products');
  
  final List<dynamic> data = response.data;
  return data.map((item) => Product.fromJson(item)).toList();
});
