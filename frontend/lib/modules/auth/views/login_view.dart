import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cloud_sky_background.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../data/providers/auth_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CloudSkyBackground(),
            SafeArea(
              child: isDesktop ? _desktopLayout(authState) : _mobileLayout(authState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopLayout(AuthState authState) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: AppDecor.softShadow,
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: 72, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (b) => AppDecor.primaryGradient.createShader(b),
                  child: const Text(
                    'BookSafe ERP',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Maamul hufan · Ganacsi guulaystay',
                  style: TextStyle(fontSize: 17, color: const Color(0xFF0F3D6E).withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: Center(child: _formCard(authState, maxWidth: 440))),
      ],
    );
  }

  Widget _mobileLayout(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: AppDecor.softShadow,
            ),
            child: const Icon(Icons.menu_book_rounded, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'BookSafe ERP',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3D6E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Maamul hufan, Ganacsi guulaystay.',
            style: TextStyle(fontSize: 13, color: const Color(0xFF0F3D6E).withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 28),
          _formCard(authState),
        ],
      ),
    );
  }

  Widget _formCard(AuthState authState, {double? maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: AppDecor.glassCard(radius: AppDecor.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ku soo dhowaw! 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textHeading),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gali macluumaadkaaga si aad nidaamka u gashid.',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 18),
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
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Ma ilowday Password-ka?'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: authState.isLoading ? null : () => _doLogin(authState),
              icon: authState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(authState.isLoading ? 'Soo galaya...' : 'Gal (Login)'),
            ),
            const SizedBox(height: 20),
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
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textHeading));

  void _doLogin(AuthState authState) {
    if (authState.isLoading) return;
    ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }
}
