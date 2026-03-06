import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiService) : super(AuthState()) {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final token = await _storage.read(key: 'token');
    final userStr = await _storage.read(key: 'user');
    
    if (token != null && userStr != null) {
      try {
        final userData = jsonDecode(userStr);
        state = state.copyWith(
          isAuthenticated: true,
          user: userData,
        );
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final userData = response.data;
      await _storage.write(key: 'token', value: userData['token']);
      await _storage.write(key: 'user', value: jsonEncode(userData));
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please check your credentials.',
      );
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.post('/auth/register-tenant', data: data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Diiwaangelintu waa fashilantay. Fadlan isku day mar kale.',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    state = AuthState();
  }

  Future<void> setImpersonation(Map<String, dynamic> data) async {
    await _storage.write(key: 'token', value: data['token']);
    await _storage.write(key: 'user', value: jsonEncode(data['user']));
    state = state.copyWith(
      isAuthenticated: true,
      user: data['user'],
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

// A stable listenable that persists for the app lifetime
final authRefreshListenableProvider = Provider<AuthRefreshListenable>((ref) {
  final listenable = AuthRefreshListenable();
  ref.listen<AuthState>(authProvider, (_, next) {
    listenable.notify();
  });
  return listenable;
});

class AuthRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
