import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_service.dart';

class BranchesView extends ConsumerStatefulWidget {
  const BranchesView({super.key});

  @override
  ConsumerState<BranchesView> createState() => _BranchesViewState();
}

class _BranchesViewState extends ConsumerState<BranchesView> {
  bool _isLoading = true;
  List<dynamic> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final res = await apiService.get('/branches');
      
      setState(() {
        _branches = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading branches: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Branch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location / Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
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
                await apiService.post('/branches', data: {
                  'branch_name': nameController.text,
                  'location': locationController.text,
                  'phone': phoneController.text,
                });
                if (mounted) Navigator.pop(context);
                _loadBranches();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Save Branch'),
          ),
        ],
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
                Text('Branch Management', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: _showAddBranchDialog,
                  icon: const Icon(Icons.add_business),
                  label: const Text('Add Branch'),
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
              child: ListView.builder(
                itemCount: _branches.length,
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.store, color: Colors.white),
                      ),
                      title: Text(branch['branch_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${branch['location'] ?? ''} - ${branch['phone'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.textLight),
                        onPressed: () {
                          // Todo edit branch
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
