import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/unit_model.dart';

final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get('/units');
  
  final List<dynamic> data = response.data;
  return data.map((item) => Unit.fromJson(item)).toList();
});
