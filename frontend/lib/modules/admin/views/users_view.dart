import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_service.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key});

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      
      final usersRes = await apiService.get('/users');
      final branchesRes = await apiService.get('/branches');
      
      setState(() {
        _users = usersRes.data is List ? usersRes.data : [];
        _branches = branchesRes.data is List ? branchesRes.data : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'cashier';
    int? selectedBranch;

    if (_branches.isNotEmpty) {
      selectedBranch = _branches.first['id'];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'branch_manager', child: Text('Branch Manager')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_branches.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedBranch,
                    decoration: const InputDecoration(labelText: 'Assign to Branch'),
                    items: _branches.map((b) => DropdownMenuItem<int>(
                      value: b['id'],
                      child: Text(b['branch_name'] ?? 'Unknown'),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedBranch = value);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final apiService = ref.read(apiServiceProvider);
                  await apiService.post('/users', data: {
                    'full_name': nameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'role': selectedRole,
                    'branch_id': selectedBranch,
                  });
                  if (mounted) Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('Save User'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('User Management', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                      ],
                    ),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Full Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _users.map((user) => DataRow(
                        cells: [
                          DataCell(Text(user['full_name'] ?? 'N/A')),
                          DataCell(Text(user['email'] ?? 'N/A')),
                          DataCell(Text(user['role']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A')),
                          DataCell(Text(user['status'] ?? 'N/A')),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
