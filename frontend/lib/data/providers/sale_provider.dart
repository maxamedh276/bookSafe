import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/sale_model.dart';

final salesProvider = FutureProvider<List<Sale>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get('/sales');
  
  final List<dynamic> data = response.data;
  return data.map((item) => Sale.fromJson(item)).toList();
});
