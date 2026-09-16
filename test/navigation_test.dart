import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:naya_santha/features/profile/presentation/profile_providers.dart';
import 'package:naya_santha/features/profile/presentation/profile_screen.dart';
import 'package:naya_santha/features/pantry/presentation/pantry_providers.dart';
import 'package:naya_santha/features/pantry/presentation/pantry_screen.dart';
import 'package:naya_santha/features/basket/presentation/basket_providers.dart';
import 'package:naya_santha/features/basket/domain/basket_models.dart';
import 'household_setup_test.dart'
    show FakeProfileRepository, FakePantryRepository;

import 'package:naya_santha/core/router/app_router.dart';
import 'package:naya_santha/core/router/routes.dart';
import 'package:naya_santha/core/theme/app_theme.dart';
import 'package:naya_santha/state/app_state.dart';
import 'package:naya_santha/state/assistant_state.dart';

class EmptyBasket extends BasketNotifier {
  @override
  Future<Basket> build() async => const Basket(
      id: 'test',
      status: 'OPEN',
      itemCount: 0,
      estimatedTotal: 0,
      maximumPayable: 0,
      items: []);
}

/// Regression test for the tab-overlap bug: switching bottom-nav tabs used a
/// slide transition, which briefly stacked the outgoing screen under the
/// incoming one. Because the tab screens paint no full-screen background, the
/// old screen showed through. The fix routes shell tabs through
/// NoTransitionPage, so the swap is instant and the previous screen is never
/// mounted alongside the next one.
void main() {
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final GoRouter router = buildRouter();
    addTearDown(router.dispose);
    router.go(Routes.profile);
    await tester.pumpWidget(
      ProviderScope(
          overrides: [
            profileRepositoryProvider
                .overrideWithValue(FakeProfileRepository()),
            pantryRepositoryProvider.overrideWithValue(FakePantryRepository()),
            basketProvider.overrideWith(EmptyBasket.new),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>(create: (_) => AppState()),
              ChangeNotifierProvider<AssistantState>(
                  create: (_) => AssistantState()),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light(),
            ),
          )),
    );
    await tester.pump();
    return router;
  }

  testWidgets('switching tabs does not leave the previous screen mounted',
      (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    // Land on the Profile tab.
    router.go(Routes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsWidgets,
        reason: 'Profile screen should be showing');

    // Switch to Pantry and pump a SINGLE frame. With NoTransitionPage the swap
    // completes immediately; a slide transition would still have Profile in the
    // tree here, so this is what catches the regression.
    router.go(Routes.pantry);
    await tester.pump();

    expect(find.byType(ProfileScreen), findsNothing,
        reason: 'previous tab must not stay mounted during the switch');
    expect(find.byType(PantryScreen), findsWidgets,
        reason: 'Pantry screen should be showing after the swap');

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
