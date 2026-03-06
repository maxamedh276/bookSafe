import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/customer_model.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get('/customers');
  
  final List<dynamic> data = response.data;
  return data.map((item) => Customer.fromJson(item)).toList();
});
