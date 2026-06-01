import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/unit_model.dart';

final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    final response = await apiService.get('/units');
    final data = response.data;
    if (data is! List) return [];
    return data.map((item) => Unit.fromJson(item as Map<String, dynamic>)).toList();
  } catch (e) {
    throw apiService.getErrorMessage(e);
  }
});
