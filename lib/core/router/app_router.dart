import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account_screens.dart';
import '../../features/auth_screens.dart';
import '../../features/checkout_screens.dart';
import '../../features/home_screen.dart';
import '../../features/lifestyle_screens.dart';
import '../../features/offers_screen.dart';
import '../../features/onboarding_screens.dart';
import '../../features/basket/presentation/basket_screen.dart';
import '../../features/catalogue/presentation/catalogue_screen.dart';
import '../../features/shopping_screens.dart' hide BasketScreen;
import '../../features/weekly_plan_screen.dart';
import '../widgets/app_shell.dart';
import 'routes.dart';

/// Instant page swap for shell/tab routes — no slide animation, so screens
/// never stack over one another during a transition.
NoTransitionPage<void> _shellPage(Widget child) =>
    NoTransitionPage<void>(child: child);

/// Routes are grouped into three sets:
///  - standalone (splash, auth, onboarding): no navigation chrome
///  - shell routes: wrapped in [AppShell] (bottom nav on mobile, sidebar on web)
///  - full-screen flows (basket -> payment, tracking): own Scaffold and app bar
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.otp, builder: (_, __) => const OtpScreen()),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.familyProfile,
        builder: (_, __) => const FamilyProfileScreen(),
      ),
      GoRoute(
        path: Routes.address,
        builder: (_, __) => const AddressScreen(),
      ),
      GoRoute(
        path: Routes.dietary,
        builder: (_, __) => const DietaryScreen(),
      ),
      GoRoute(
        path: Routes.kitchen,
        builder: (_, __) => const KitchenSetupScreen(),
      ),

      // --- Shell routes ------------------------------------------------------
      // Tab screens swap instantly (NoTransitionPage): a slide transition would
      // stack the outgoing screen under the incoming one, and because the
      // screens paint no full-screen background, the old screen shows through.
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, __) => _shellPage(const HomeScreen()),
          ),
          GoRoute(
            path: Routes.weeklyPlan,
            pageBuilder: (_, __) => _shellPage(const WeeklyPlanScreen()),
          ),
          GoRoute(
            path: Routes.categories,
            // Dynamic catalogue backed by the API (replaces mock CategoriesScreen).
            pageBuilder: (BuildContext c, GoRouterState s) =>
                _shellPage(const CatalogueScreen()),
          ),
          GoRoute(
            path: Routes.pantry,
            pageBuilder: (_, __) => _shellPage(const PantryScreen()),
          ),
          GoRoute(
            path: Routes.recipes,
            pageBuilder: (_, __) => _shellPage(const RecipesScreen()),
          ),
          GoRoute(
            path: Routes.budget,
            pageBuilder: (_, __) => _shellPage(const BudgetScreen()),
          ),
          GoRoute(
            path: Routes.offers,
            pageBuilder: (_, __) => _shellPage(const OffersScreen()),
          ),
          GoRoute(
            path: Routes.subscription,
            pageBuilder: (_, __) => _shellPage(const SubscriptionScreen()),
          ),
          GoRoute(
            path: Routes.wallet,
            pageBuilder: (_, __) => _shellPage(const WalletScreen()),
          ),
          GoRoute(
            path: Routes.orders,
            pageBuilder: (_, __) => _shellPage(const OrdersScreen()),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, __) => _shellPage(const ProfileScreen()),
          ),
        ],
      ),

      // --- Full-screen flows -------------------------------------------------
      GoRoute(path: Routes.basket, builder: (_, __) => const BasketScreen()),
      GoRoute(
        path: '${Routes.product}/:id',
        builder: (BuildContext c, GoRouterState s) =>
            ProductDetailScreen(productId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: Routes.search, builder: (_, __) => const SearchScreen()),
      GoRoute(path: Routes.checkout, builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: Routes.payment, builder: (_, __) => const PaymentScreen()),
      GoRoute(
        path: '${Routes.orderSuccess}/:id',
        builder: (BuildContext c, GoRouterState s) =>
            OrderSuccessScreen(orderId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.tracking}/:id',
        builder: (BuildContext c, GoRouterState s) =>
            TrackingScreen(orderId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.assistant,
        builder: (_, __) => const AssistantScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: Routes.referral, builder: (_, __) => const ReferralScreen()),
      GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
    ],
    errorBuilder: (BuildContext c, GoRouterState s) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('That page does not exist.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => c.go(Routes.home),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
}
