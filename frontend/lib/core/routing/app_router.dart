import 'package:go_router/go_router.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/register_view.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/sales/views/sales_view.dart';
import '../../modules/inventory/views/inventory_view.dart';
import '../../modules/customers/views/customers_view.dart';
import '../../modules/customers/views/customer_detail_view.dart';
import '../../modules/debts/views/debts_view.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/reports/views/reports_view.dart';
import '../../modules/admin/views/tenants_list_view.dart';
import '../../modules/admin/views/users_view.dart';
import '../../modules/admin/views/branches_view.dart';
import '../widgets/main_layout.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use read instead of watch for the listenable to prevent router recreation
  final refreshListenable = ref.read(authRefreshListenableProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isLoggingIn = loc == '/login' || loc == '/register';

      if (isSplash) {
        if (isAuth) return '/';
        return null;
      }

      if (!isAuth && !isLoggingIn) return '/splash';
      if (isAuth && isLoggingIn) return '/';

      // IT admin manages tenants via /admin, not /users
      final role = authState.user?['role']?.toString() ?? '';
      if (isAuth && role == 'it_admin' && state.matchedLocation == '/users') {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      
      // Main Application Shell
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesView(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryView(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersView(),
          ),
          GoRoute(
            path: '/customers/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CustomerDetailView(customerId: id);
            },
          ),
          GoRoute(
            path: '/debts',
            builder: (context, state) => const DebtsView(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsView(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const TenantsListView(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersView(),
          ),
          GoRoute(
            path: '/branches',
            builder: (context, state) => const BranchesView(),
          ),
        ],
      ),
    ],
  );
});
