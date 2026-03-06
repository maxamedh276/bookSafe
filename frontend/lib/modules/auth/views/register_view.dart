import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedPlan = 'basic';

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'business_name': _businessNameController.text,
        'owner_name': _ownerNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'subscription_plan': _selectedPlan,
        'password': _passwordController.text,
      };
      
      await ref.read(authProvider.notifier).register(data);
      
      if (mounted && ref.read(authProvider).error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diiwaangelintu waa guul! Fadlan sug inta IT Admin-ku ogolaanayo.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Is-diiwaangeli'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textHeading),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dhis Ganacsigaaga BookSafe',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fadlan buuxi foomka hoose si aad ugu biirtid nidaamka.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 40),
                  
                  // Business Name
                  _buildLabel('Magaca Ganacsiga'),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(hintText: 'Tusaale: BookSafe Shop'),
                    validator: (v) => v!.isEmpty ? 'Fadlan gali magaca ganacsiga' : null,
                  ),
                  const SizedBox(height: 20),

                  // Owner Name
                  _buildLabel('Magaca Milkiilaha'),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(hintText: 'Gali magacaaga oo buuxa'),
                    validator: (v) => v!.isEmpty ? 'Fadlan gali magaca milkiilaha' : null,
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _buildLabel('Email-ka'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'email@gmail.com'),
                    validator: (v) => v!.isEmpty ? 'Fadlan gali email-ka' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  _buildLabel('Lambarka Taleefanka'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '61XXXXXXX'),
                    validator: (v) => v!.isEmpty ? 'Fadlan gali lambarka' : null,
                  ),
                  const SizedBox(height: 20),

                  // Address
                  _buildLabel('Cinwaanka'),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Mogadishu, Somalia'),
                  ),
                  const SizedBox(height: 20),

                  // Subscription Plan
                  _buildLabel('Qorshaha (Subscription Plan)'),
                  DropdownButtonFormField<String>(
                    value: _selectedPlan,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'basic', child: Text('Basic (1 Branch)')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium (Multiple Branches)')),
                    ],
                    onChanged: (v) => setState(() => _selectedPlan = v!),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _buildLabel('Password-ka Dashboard-ka'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: '••••••••'),
                    validator: (v) => v!.length < 6 ? 'Password-ku waa inuu ka badnaadaa 6 xaraf' : null,
                  ),
                  const SizedBox(height: 40),

                  // Register Button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _onRegister,
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Gudbi Codsiga', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  
                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Account hore ma leedahay?'),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
