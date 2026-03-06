import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../services/offline_sync_service.dart';
import '../i18n/app_strings.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Returns the nav items visible to this user's role
  List<_NavItem> _navItems(String role, AppStrings s) {
    return [
      _NavItem(s.dashboard,    Icons.dashboard_outlined,              '/'),
      _NavItem(s.sales,        Icons.shopping_cart_outlined,          '/sales'),
      _NavItem(s.inventory,    Icons.inventory_2_outlined,            '/inventory'),
      _NavItem(s.customers,    Icons.people_outline,                  '/customers'),
      _NavItem(s.debts,        Icons.account_balance_wallet_outlined, '/debts'),
      _NavItem(s.reports,      Icons.bar_chart_outlined,              '/reports'),
      if (role == 'tenant_admin' || role == 'it_admin') ...[
        _NavItem(s.users,    Icons.manage_accounts_outlined, '/users'),
        _NavItem(s.branches, Icons.store_outlined,           '/branches'),
      ],
      if (role == 'it_admin')
        _NavItem(s.adminPanel, Icons.admin_panel_settings_outlined, '/admin'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s    = ref.watch(stringsProvider);
    final role = ref.watch(authProvider).user?['role'] ?? '';
    final items = _navItems(role, s);

    // Breakpoints
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isTablet  = width > 600 && width <= 1000;
    final isMobile  = width <= 600;

    // On mobile show bottom nav for the first 6 items max
    final bottomItems = items.take(5).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        // Mobile: slide-out drawer (tablet uses same)
        drawer: !isDesktop
            ? _buildDrawer(items: items, s: s, role: role)
            : null,
        // Mobile bottom nav
        bottomNavigationBar: isMobile
            ? _buildBottomNav(bottomItems)
            : null,
        body: SafeArea(
          bottom: false, // let bottomNav handle bottom safe area
          child: Column(
            children: [
              // ── Offline Banner ──────────────────────────────────
              const OfflineBanner(),

              Expanded(
                child: Row(
                  children: [
                    // Desktop permanent sidebar
                    if (isDesktop)
                      _buildSidebarContent(items: items, s: s, role: role, shrink: false),

                    // Tablet: narrow icon-only sidebar
                    if (isTablet)
                      _buildSidebarContent(items: items, s: s, role: role, shrink: true),

                    // Main content
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBar(s, isMobile: isMobile || isTablet),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── TOP BAR ────────────────────────────
  Widget _buildTopBar(AppStrings s, {required bool isMobile}) {
    final user = ref.watch(authProvider).user;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            ),
          const Spacer(),
          // Sync button
          const SyncPendingButton(),
          const SizedBox(width: 4),
          // Language toggle
          _buildLangToggle(),
          const SizedBox(width: 12),
          // Avatar + name
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(user?['full_name'] ?? 'Guest',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                user?['role']?.toString().replaceAll('_', ' ').toUpperCase() ?? '',
                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── LANGUAGE TOGGLE ─────────────────────
  Widget _buildLangToggle() {
    final locale = ref.watch(localeProvider);
    final isSomali = locale.languageCode == 'so';
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isSomali ? '🇸🇴' : '🇬🇧', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              isSomali ? 'SO' : 'EN',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── DRAWER (mobile/tablet) ──────────────
  Widget _buildDrawer({required List<_NavItem> items, required AppStrings s, required String role}) {
    return Drawer(
      backgroundColor: AppColors.secondary,
      child: SafeArea(
        child: Column(
          children: [
            // Logo header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'BookSafe',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, i) => _drawerItem(items[i], i),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Logout
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: const Icon(Icons.logout_rounded, color: Colors.white60),
              title: Text(s.logout, style: const TextStyle(color: Colors.white60)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(_NavItem item, int index) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(item.icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
          context.go(item.route);
        },
      ),
    );
  }

  // ─────────────────────────── DESKTOP/TABLET SIDEBAR ──────────────
  Widget _buildSidebarContent({
    required List<_NavItem> items,
    required AppStrings s,
    required String role,
    required bool shrink,
  }) {
    final w = shrink ? 68.0 : 250.0;
    return Container(
      width: w,
      color: AppColors.secondary,
      child: Column(
        children: [
          // Logo
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: shrink ? 0 : 16),
            alignment: shrink ? Alignment.center : Alignment.centerLeft,
            child: shrink
                ? const Icon(Icons.menu_book, color: AppColors.primary, size: 26)
                : const Row(
                    children: [
                      Icon(Icons.menu_book, color: AppColors.primary, size: 26),
                      SizedBox(width: 10),
                      Text('BookSafe', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, i) => _sidebarItem(items[i], i, shrink),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Logout
          Padding(
            padding: EdgeInsets.symmetric(horizontal: shrink ? 4 : 8, vertical: 8),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.logout_rounded, color: Colors.white60, size: 20),
              title: shrink ? null : Text(s.logout, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(_NavItem item, int index, bool shrink) {
    final isSelected = _selectedIndex == index;
    if (shrink) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Tooltip(
          message: item.label,
          child: InkWell(
            onTap: () {
              setState(() => _selectedIndex = index);
              context.go(item.route);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(item.icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          context.go(item.route);
        },
      ),
    );
  }

  // ─────────────────────────── BOTTOM NAV (mobile) ─────────────────
  Widget _buildBottomNav(List<_NavItem> items) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isSelected = _selectedIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = i);
                  context.go(item.route);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? AppColors.primary : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}
