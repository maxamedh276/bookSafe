import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/services/receipt_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/services/offline_sync_service.dart';

class SalesView extends ConsumerStatefulWidget {
  const SalesView({super.key});

  @override
  ConsumerState<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends ConsumerState<SalesView> {
  String searchQuery = '';
  Customer? selectedCustomer;
  String paymentStatus = 'paid'; // 'paid' or 'credit'

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final customersAsync = ref.watch(customersProvider);
    final cart = ref.watch(cartProvider);
    final totalAmount = cart.fold<double>(0, (sum, item) => sum + item.total);

    final width = MediaQuery.of(context).size.width;
    final isMobileScreen = width < 800; // Mobile breakpoint
    final isTabletScreen = width >= 800 && width < 1200; // Tablet breakpoint

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        // Show FAB on mobile and tablet for quick add
        floatingActionButton: (isMobileScreen || isTabletScreen)
            ? FloatingActionButton.extended(
                onPressed: () => _showQuickAddProduct(context),
                icon: const Icon(Icons.add),
                label: const Text('Ku dar Alaab'),
              )
            : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1000;
          final isMobile = constraints.maxWidth < 800;
          final rightPanelWidth = isMobile ? constraints.maxWidth : (isNarrow ? constraints.maxWidth * 0.45 : 420.0);
          
          final Widget productsSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Action Bar
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Ka raadi alaab...',
                                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _showQuickAddProduct(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Alaab', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Product Grid
                    Expanded(
                      child: productsAsync.when(
                        data: (products) {
                          final filtered = products.where((p) {
                            final name = p.name.toLowerCase();
                            final sku = (p.sku ?? '').toLowerCase();
                            final query = searchQuery.toLowerCase();
                            return name.contains(query) || sku.contains(query);
                          }).toList();
                          final hasSearch = searchQuery.trim().isNotEmpty;

                          // No products at all: show "Add product" empty state
                          if (products.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primary),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Ma jiro wax alaab ah weli.',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Ku dar alaabtaada adigoo riixaya “Ku dar Alaab Cusub” si aad u bilowdo iibka.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => _showQuickAddProduct(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Ku dar Alaab Cusub'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Products exist but filter returned nothing
                          if (filtered.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off_rounded, size: 56, color: AppColors.primary),
                                    const SizedBox(height: 12),
                                    Text(
                                      hasSearch ? 'Ma jirto alaab ku habboon raadinta.' : 'Ma jirto alaab la helay.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    if (hasSearch)
                                      TextButton(
                                        onPressed: () => setState(() => searchQuery = ''),
                                        child: const Text('Nadiifi raadinta'),
                                      ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _showQuickAddProduct(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Ku dar Alaab Cusub'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: constraints.maxWidth > 1400 ? 4 : (constraints.maxWidth > 1100 ? 3 : 2),
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildProductCard(filtered[index]),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                                const SizedBox(height: 8),
                                const Text('Walaabta lama soo rari karin', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                  e.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => ref.invalidate(productsProvider),
                                  child: const Text('Isku day mar kale'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              
              // Right Side: Cart & Details
              final Widget cartSection = Container(
                width: rightPanelWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-2, 0)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diiwaanka Iibka',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),

                            // Customer Selection
                            const Text('Macaamiilka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: customersAsync.when(
                                    data: (customers) {
                                      final currentCustomer = customers.any((c) => c.id == selectedCustomer?.id) 
                                          ? customers.firstWhere((c) => c.id == selectedCustomer?.id)
                                          : null;

                                      if (customers.isEmpty) {
                                        return const Text(
                                          'Diiwaanka macmiil kuma jiro. Fadlan mid ku dar.',
                                          style: TextStyle(color: AppColors.error, fontSize: 13),
                                        );
                                      }

                                      return DropdownMenu<Customer>(
                                        initialSelection: currentCustomer,
                                        expandedInsets: EdgeInsets.zero,
                                        hintText: 'Baadh ama Dooro Macmiil...',
                                        textStyle: const TextStyle(fontSize: 13),
                                        inputDecorationTheme: InputDecorationTheme(
                                          fillColor: AppColors.background,
                                          filled: true,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                        ),
                                        dropdownMenuEntries: customers.map((c) => DropdownMenuEntry<Customer>(
                                          value: c,
                                          label: c.name,
                                        )).toList(),
                                        onSelected: (v) {
                                          if (v != null) {
                                            setState(() => selectedCustomer = v);
                                          }
                                        },
                                      );
                                    },
                                    loading: () => const LinearProgressIndicator(),
                                    error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red, fontSize: 10)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 28),
                                  onPressed: () => _showQuickAddCustomer(context),
                                  tooltip: 'Macmiil Cusub',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Payment Toggle
                            const Text('Habka Lacag Bixinta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildPaymentOption('paid', 'Kash', Icons.money),
                                const SizedBox(width: 8),
                                _buildPaymentOption('credit', 'Deyn', Icons.credit_card),
                              ],
                            ),
                            
                            const Divider(height: 48),

                            // Cart Items
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Alaabta Iibka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (cart.isNotEmpty)
                                  TextButton(
                                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                                    child: const Text('Tirtir', style: TextStyle(color: AppColors.error)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (cart.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: Text('Cart-ku waa madhan yahay.', style: TextStyle(color: Colors.grey))),
                              )
                            else
                              ...cart.map((item) => _buildCartItem(item)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Fixed Summary & Action at bottom
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSummaryRow('Warta Guud', '\$${totalAmount.toStringAsFixed(2)}', isPrimary: true),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: cart.isEmpty ? null : () => _handleCheckout(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 58),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Gudbi Iibka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isMobile) {
                // Mobile: tabbed layout with a simple vertical list for products
                return DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            const Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Alaabta'),
                            Tab(
                              icon: Badge(
                                isLabelVisible: cart.isNotEmpty,
                                label: Text('${cart.fold<int>(0, (sum, i) => sum + i.quantity)}'),
                                child: const Icon(Icons.shopping_cart_outlined),
                              ),
                              text: 'Cart-ka',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Products list (mobile-optimised)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          onChanged: (v) => setState(() => searchQuery = v),
                                          decoration: InputDecoration(
                                            hintText: 'Ka raadi alaab...',
                                            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                        tooltip: 'Ku dar Alaab',
                                        onPressed: () => _showQuickAddProduct(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: productsAsync.when(
                                    data: (products) {
                                      final filtered = products.where((p) {
                                        final name = p.name.toLowerCase();
                                        final sku = (p.sku ?? '').toLowerCase();
                                        final query = searchQuery.toLowerCase();
                                        return name.contains(query) || sku.contains(query);
                                      }).toList();
                                      final hasSearch = searchQuery.trim().isNotEmpty;

                                      if (products.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.inventory_2_outlined,
                                                    size: 56, color: AppColors.primary),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'Ma jiro wax alaab ah weli.',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Riix “Ku dar Alaab” si aad alaab cusub ugu darto.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      if (filtered.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.search_off_rounded,
                                                    size: 48, color: AppColors.primary),
                                                const SizedBox(height: 8),
                                                Text(
                                                  hasSearch
                                                      ? 'Ma jirto alaab ku habboon raadinta.'
                                                      : 'Ma jirto alaab la helay.',
                                                ),
                                                const SizedBox(height: 8),
                                                if (hasSearch)
                                                  TextButton(
                                                    onPressed: () => setState(() => searchQuery = ''),
                                                    child: const Text('Nadiifi raadinta'),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final product = filtered[index];
                                          return ListTile(
                                            tileColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: Colors.grey.withOpacity(0.1),
                                              ),
                                            ),
                                            title: Text(product.name,
                                                style: const TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text(
                                              'Qiime: \$${product.price}  •  Stock: ${product.stock}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: const Icon(Icons.add_shopping_cart_outlined,
                                                color: AppColors.primary),
                                            onTap: () => ref
                                                .read(cartProvider.notifier)
                                                .addToCart(product),
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(child: CircularProgressIndicator()),
                                    error: (e, s) => Center(child: Text('Error: $e')),
                                  ),
                                ),
                              ],
                            ),
                            // Tab 2: Cart
                            cartSection,
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: productsSection),
                    if (!isMobile) cartSection,
                  ],
                );
        },
      ),
    ));
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = paymentStatus == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => paymentStatus = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showEditPriceDialog(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x ${item.quantity}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
              ),
              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.success),
                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPriceDialog(CartItem item) async {
    final controller = TextEditingController(text: item.price.toStringAsFixed(2));
    final newValue = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Beddel qiimaha'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Qiimaha hal xabbo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Jooji'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fadlan geli qiime sax ah.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, parsed);
              },
              child: const Text('Kaydi'),
            ),
          ],
        );
      },
    );

    if (newValue != null) {
      ref.read(cartProvider.notifier).updatePrice(item.product.id, newValue);
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = true, bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isPrimary ? 18 : 14, color: isPrimary ? Colors.black87 : AppColors.textLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 24 : 16,
            fontWeight: isBold || isPrimary ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () => ref.read(cartProvider.notifier).addToCart(product),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 30)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '\$${product.price}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary, 
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.stock < 5 ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        color: product.stock < 5 ? AppColors.error : AppColors.success, 
                        fontSize: 9, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const QuickAddProductDialog(),
    ).then((value) {
      if (value == true) ref.invalidate(productsProvider);
    });
  }

  void _showQuickAddCustomer(BuildContext context) {
     showDialog(
      context: context,
      builder: (context) => const QuickAddCustomerDialog(),
    ).then((value) {
      if (value == true) ref.invalidate(customersProvider);
    });
  }

  void _handleCheckout() async {
    if (selectedCustomer == null && paymentStatus == 'credit') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan dooro macmiilka marka iibku yahay Deyn (Credit).'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final cartItems = ref.read(cartProvider);
      final totalAmt = ref.read(cartProvider.notifier).totalAmount;
      final paidAmt = paymentStatus == 'paid' ? totalAmt : 0.0;
      final debtAmt = totalAmt - paidAmt;

      final saleData = {
        'customer_id': selectedCustomer?.id,
        'payment_status': paymentStatus,
        'paid_amount': paidAmt,
        'items': cartItems.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        }).toList(),
      };

      // Build receipt items regardless of online/offline
      final receiptItems = cartItems.map((item) => {
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price.toStringAsFixed(2),
        'subtotal': item.total.toStringAsFixed(2),
      }).toList();

      final authState = ref.read(authProvider);
      final businessName = authState.user?['business_name'] ?? 'BookSafe';
      String invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // Check connectivity
      final syncService = ref.read(offlineSyncProvider);
      final online = await syncService.isOnline();

      if (online) {
        // Online: submit to server
        final api = ref.read(apiServiceProvider);
        final response = await api.post('/sales', data: saleData);
        invoiceNumber = response.data?['invoice_number'] ?? invoiceNumber;
      } else {
        // Offline: save to Hive queue
        await syncService.queueSale(saleData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📦 Internet ma jiro — Iibka ayaa locally loo keydinayaa si dib loogu soo diro.'),
              backgroundColor: Color(0xFFD97706),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      ref.read(cartProvider.notifier).clear();
      if (online) {
        ref.invalidate(productsProvider);
        if (selectedCustomer != null) ref.invalidate(customersProvider);
      }

      if (mounted) {
        if (online) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Iibka si guul leh ayaa loo gudbiyey!'), backgroundColor: AppColors.success),
          );
        }

        // Print receipt
        await ReceiptService.printReceipt(
          invoiceNumber: invoiceNumber,
          businessName: businessName,
          customerName: selectedCustomer?.name,
          paymentStatus: paymentStatus,
          items: receiptItems,
          totalAmount: totalAmt,
          paidAmount: paidAmt,
          debtAmount: debtAmt,
          saleDate: DateTime.now(),
        );

        setState(() => selectedCustomer = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class QuickAddCustomerDialog extends ConsumerStatefulWidget {
  const QuickAddCustomerDialog({super.key});

  @override
  ConsumerState<QuickAddCustomerDialog> createState() => _QuickAddCustomerDialogState();
}

class _QuickAddCustomerDialogState extends ConsumerState<QuickAddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Macmiil Cusub'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppColors.error.withOpacity(0.1),
                  child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              TextFormField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Magaca Macmiilka'),
                validator: (v) => v!.isEmpty ? 'Fadlan gali magaca' : null,
              ),
            TextFormField(
              controller: _phoneController, 
              decoration: const InputDecoration(labelText: 'Telefoonka'),
              validator: (v) => v!.isEmpty ? 'Fadlan gali telefoonka' : null,
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() {
              _isLoading = true;
              _errorMsg = null;
            });
            try {
              await ref.read(apiServiceProvider).post('/customers', data: {
                'name': _nameController.text,
                'phone': _phoneController.text,
              });
              if (mounted) Navigator.pop(context, true);
            } catch (e) {
              if (mounted) setState(() => _errorMsg = e.toString());
            } finally {
               if (mounted) setState(() => _isLoading = false);
            }
          },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Keydi'),
        ),
      ],
    );
  }
}

class QuickAddProductDialog extends ConsumerStatefulWidget {
  const QuickAddProductDialog({super.key});

  @override
  ConsumerState<QuickAddProductDialog> createState() => _QuickAddProductDialogState();
}

class _QuickAddProductDialogState extends ConsumerState<QuickAddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alaab Cusub'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: AppColors.error.withOpacity(0.1),
                  child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              TextFormField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Magaca Alaabta'),
                validator: (v) => v!.isEmpty ? 'Fadlan gali magaca' : null,
              ),
            TextFormField(
              controller: _priceController, 
              decoration: const InputDecoration(labelText: 'Qiimaha'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Fadlan gali qiimaha' : null,
            ),
            TextFormField(
              controller: _stockController, 
              decoration: const InputDecoration(labelText: 'Tirada (Stock)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Fadlan gali tirada' : null,
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() {
              _isLoading = true;
              _errorMsg = null;
            });
            try {
              await ref.read(apiServiceProvider).post('/products', data: {
                'name': _nameController.text,
                'price': double.parse(_priceController.text),
                'stock': int.parse(_stockController.text),
              });
              if (mounted) Navigator.pop(context, true);
            } catch (e) {
              if (mounted) setState(() => _errorMsg = e.toString());
            } finally {
               if (mounted) setState(() => _isLoading = false);
            }
          },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Keydi'),
        ),
      ],
    );
  }
}
