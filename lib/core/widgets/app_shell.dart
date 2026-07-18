import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../router/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.route, {this.mobile = false});

  final String label;
  final IconData icon;
  final String route;

  /// Whether this item appears in the mobile bottom bar.
  final bool mobile;
}

const List<NavItem> kNavItems = <NavItem>[
  NavItem('Home', Icons.home_outlined, Routes.home, mobile: true),
  NavItem('AI Weekly Plan', Icons.auto_awesome_outlined, Routes.weeklyPlan,
      mobile: true),
  NavItem('Categories', Icons.grid_view_outlined, Routes.categories),
  NavItem('Pantry', Icons.kitchen_outlined, Routes.pantry, mobile: true),
  NavItem('Orders', Icons.receipt_long_outlined, Routes.orders),
  NavItem('Subscription', Icons.workspace_premium_outlined, Routes.subscription),
  NavItem('Wallet', Icons.account_balance_wallet_outlined, Routes.wallet),
  NavItem('Recipes', Icons.menu_book_outlined, Routes.recipes),
  NavItem('Offers', Icons.local_offer_outlined, Routes.offers),
  NavItem('Budget', Icons.insights_outlined, Routes.budget),
  NavItem('Profile', Icons.person_outline, Routes.profile, mobile: true),
];

/// Wraps every signed-in screen. Chooses navigation chrome by viewport width.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool wide = Breakpoints.isDesktop(context);
    return wide ? _WideShell(child: child) : _CompactShell(child: child);
  }
}

// ---------------------------------------------------------------------------
// Mobile / tablet
// ---------------------------------------------------------------------------

class _CompactShell extends StatelessWidget {
  const _CompactShell({required this.child});

  final Widget child;

  static final List<NavItem> _items =
      kNavItems.where((NavItem i) => i.mobile).toList();

  int _indexFor(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _indexFor(context),
          onDestinationSelected: (int i) => context.go(_items[i].route),
          destinations: _items
              .map(
                (NavItem i) => NavigationDestination(
                  icon: Icon(i.icon),
                  selectedIcon: Icon(i.icon, color: AppColors.primary),
                  label: i.label == 'AI Weekly Plan' ? 'Plan' : i.label,
                ),
              )
              .toList(),
        ),
      ),
      floatingActionButton: app.basketCount == 0
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              onPressed: () => context.go(Routes.basket),
              icon: const Icon(Icons.shopping_basket_outlined),
              label: Text('${app.basketCount} · ${money(app.basketSubtotal)}'),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop web
// ---------------------------------------------------------------------------

class _WideShell extends StatelessWidget {
  const _WideShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final String location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: <Widget>[
          Container(
            width: 236,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, Gap.lg),
                  child: BrandLockup(size: 20),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                    children: kNavItems.map((NavItem item) {
                      final bool active = location.startsWith(item.route);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Radii.md),
                          onTap: () => context.go(item.route),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Gap.md, vertical: 11),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.surfaceMuted
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(Radii.md),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  item.icon,
                                  size: 19,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: Gap.md),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? AppColors.forest
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, size: 19),
                  title: const Text('Sign out', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    app.signOut();
                    context.go(Routes.welcome);
                  },
                ),
                const SizedBox(height: Gap.sm),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(app: app),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.location_on_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Delivering to',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                app.defaultAddress.label,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: Gap.xl),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SizedBox(
                height: 40,
                child: TextField(
                  readOnly: true,
                  onTap: () => context.go(Routes.search),
                  decoration: const InputDecoration(
                    hintText: 'Search products, categories, recipes',
                    prefixIcon: Icon(Icons.search, size: 19),
                    contentPadding: EdgeInsets.zero,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Gap.lg),
          _IconBadge(
            icon: Icons.notifications_none,
            count: app.unreadCount,
            onTap: () => context.go(Routes.notifications),
          ),
          const SizedBox(width: Gap.sm),
          _IconBadge(
            icon: Icons.shopping_basket_outlined,
            count: app.basketCount,
            onTap: () => context.go(Routes.basket),
          ),
          const SizedBox(width: Gap.lg),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.surfaceMuted,
            child: Text(
              app.name.isNotEmpty ? app.name[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconButton(onPressed: onTap, icon: Icon(icon, size: 21)),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.tomato,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
