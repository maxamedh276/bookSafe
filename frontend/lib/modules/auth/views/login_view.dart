import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size      = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: isDesktop ? _desktopLayout(authState) : _mobileLayout(authState),
        ),
      ),
    );
  }

  // ──────────────────── DESKTOP ────────────────────
  Widget _desktopLayout(AuthState authState) {
    return Row(
      children: [
        // Branding panel
        Expanded(
          child: Container(
            color: AppColors.primary,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  const Text('BookSafe ERP',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  const Text('Maamul hufan, Ganacsi guulaystay.',
                      style: TextStyle(color: Colors.white70, fontSize: 17)),
                ],
              ),
            ),
          ),
        ),
        // Form panel
        Expanded(child: _formContent(authState)),
      ],
    );
  }

  // ──────────────────── MOBILE ─────────────────────
  Widget _mobileLayout(AuthState authState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Mobile brand header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text('BookSafe ERP',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Maamul hufan, Ganacsi guulaystay.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          // Form below
          _formContent(authState),
        ],
      ),
    );
  }

  // ──────────────────── SHARED FORM ────────────────
  Widget _formContent(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ku soo dhowaw! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Gali macluumaadkaaga si aad nidaamka u gashid.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
              const SizedBox(height: 36),

              // Email
              _label('Email-ka'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'admin@booksafe.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              _label('Password-ka'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _doLogin(authState),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Ma ilowday Password-ka?'),
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : () => _doLogin(authState),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Gal (Login)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ganacsi cusub ma tahay?'),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Is dhiwaangeli'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));

  void _doLogin(AuthState authState) {
    if (authState.isLoading) return;
    ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }
}
