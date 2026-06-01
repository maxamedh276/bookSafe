import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Model for User (partial fields needed for UI)
class User {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final int? branchId;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.branchId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        branchId: json['branch_id'] as int?,
      );
}

// State class holding list and loading/error status
class UsersState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  UsersState({required this.users, this.isLoading = false, this.error});

  UsersState copyWith({List<User>? users, bool? isLoading, String? error}) =>
      UsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class UsersNotifier extends StateNotifier<UsersState> {
  final ApiService _api;

  UsersNotifier(this._api) : super(UsersState(users: [])) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get('/users');
      final List<dynamic> data = res.data as List<dynamic>;
      final users = data.map((e) => User.fromJson(e)).toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _api.getErrorMessage(e));
    }
  }

  Future<bool> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    int? branchId,
  }) async {
    try {
      final payload = {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
        if (branchId != null) 'branch_id': branchId,
      };
      await _api.post('/users', data: payload);
      // Refresh list after creation
      await fetchUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: _api.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateUser({
    required int id,
    String? fullName,
    String? email,
    String? role,
    int? branchId,
    String? status,
  }) async {
    try {
      final payload = {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (role != null) 'role': role,
        if (branchId != null) 'branch_id': branchId,
        if (status != null) 'status': status,
      };
      await _api.put('/users/$id', data: payload);
      await fetchUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: _api.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _api.delete('/users/$id');
      await fetchUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: _api.getErrorMessage(e));
      return false;
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final api = ref.read(apiServiceProvider);
  return UsersNotifier(api);
});
