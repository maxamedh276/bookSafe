import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';

class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends ConsumerState<InventoryView> {
  String searchQuery = '';

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    ).then((value) {
      if (value == true) {
        ref.invalidate(productsProvider);
      }
    });
  }

  Future<void> _showEditProductDialog(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku ?? '');
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'SKU / Barcode'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.put('/products/${product.id}', data: {
          'name': nameController.text,
          'sku': skuController.text,
          'price': double.tryParse(priceController.text) ?? product.price,
          'stock': int.tryParse(stockController.text) ?? product.stock,
        });
        ref.invalidate(productsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Ma hubtaa inaad tirtirayso "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ka noqo'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.delete('/products/${product.id}');
        ref.invalidate(productsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileScreen = width < 800;

    final productsAsync = ref.watch(productsProvider);

    // ───────────── MOBILE LAYOUT (simple list, no advanced table) ─────────────
    if (isMobileScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: const Text('Alaab Cusub'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bakhaarka',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Maamul alaabtaada iyo stock-gaaga.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search Field for Mobile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Alaab ama SKU ku dhex raadi...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = products.where((p) =>
                        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (p.sku?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(searchQuery.isEmpty ? 'Bakhaarka waa madhan yahay.' : 'Ma jirto alaab ku habboon raadinta.'),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(productsProvider);
                        await ref.read(productsProvider.future);
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isOutOfStock = p.stock <= 0;
                          final isLowStock = p.stock > 0 && p.stock <= 5;
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('SKU: ${p.sku ?? "-"} • \$${p.price.toStringAsFixed(2)}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${p.stock}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock ? AppColors.error : (isLowStock ? AppColors.warning : AppColors.success),
                                    )),
                                const Text('Stock', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            onTap: () => _showEditProductDialog(p),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ───────────── DESKTOP / TABLET LAYOUT (original table) ─────────────
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bakhaarka (Inventory)',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('Maamul alaabtaada iyo stock-gaaga.'),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Alaab Cusub'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search & Filters
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search products by name or SKU...',
                        hintStyle: const TextStyle(color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => searchQuery = ''),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filters', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Products list/table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: productsAsync.when(
                  data: (products) {
                    final filtered = products.where((p) =>
                        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (p.sku?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)).toList();

                    if (isMobileScreen) {
                      // Mobile: simple list
                      if (products.isEmpty) {
                        return const Center(
                          child: Text('Alaab bakhaarka kuma jirto weli.'),
                        );
                      }
                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('Ma jirto alaab ku habboon raadinta.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final isLowStock = product.stock <= 5;
                          return ListTile(
                            title: Text(product.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'SKU: ${product.sku ?? '-'} • Qiime: \$${product.price} • Stock: ${product.stock}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLowStock ? 'Low' : 'OK',
                                style: TextStyle(
                                  color: isLowStock ? AppColors.error : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // Desktop/tablet: DataTable
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(productsProvider);
                        await ref.read(productsProvider.future);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowColor: MaterialStateProperty.all(AppColors.background),
                          columns: const [
                            DataColumn(
                                label: Text('Product Name',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                                label:
                                    Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Price',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Stock',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Status',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Actions',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((product) {
                            final isLowStock = product.stock <= 5;
                            return DataRow(
                              cells: [
                                DataCell(Text(product.name)),
                                DataCell(Text(product.sku ?? '-')),
                                DataCell(Text('\$${product.price}')),
                                DataCell(Text('${product.stock}')),
                                DataCell(
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLowStock
                                          ? AppColors.error.withOpacity(0.1)
                                          : AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLowStock ? 'Low Stock' : 'In Stock',
                                      style: TextStyle(
                                        color: isLowStock ? AppColors.error : AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showEditProductDialog(product)),
                                    IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.error),
                                        onPressed: () => _deleteProduct(product)),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.post('/products', data: {
          'name': _nameController.text,
          'sku': _skuController.text,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
        });
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alaabta waa lagu daray!'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kudar Alaab Cusub'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Magaca Alaabta'),
                validator: (v) => v!.isEmpty ? 'Gali magaca' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU / Barcode'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Qiimaha (\$)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Gali qiimaha' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Tirada (Stock)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Gali tirada' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Keydi'),
        ),
      ],
    );
  }
}
