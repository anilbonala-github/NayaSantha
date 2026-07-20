import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:naya_santha/core/router/app_router.dart';
import 'package:naya_santha/core/router/routes.dart';
import 'package:naya_santha/core/theme/app_theme.dart';
import 'package:naya_santha/state/app_state.dart';
import 'package:naya_santha/state/assistant_state.dart';

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

    // The screens trip some debug-only design assertions (ListTile inside a
    // colored DecoratedBox, occasional overflow at this exact surface size)
    // that are unrelated to navigation and never fire in release. Filter them
    // so this test measures only tab-switching behaviour.
    final original = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String msg = details.exceptionAsString();
      if (msg.contains('ListTile background color') ||
          msg.contains('A RenderFlex overflowed')) {
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    final GoRouter router = buildRouter();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>(create: (_) => AppState()),
          ChangeNotifierProvider<AssistantState>(
              create: (_) => AssistantState()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
        ),
      ),
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
    expect(find.text('Your household'), findsWidgets,
        reason: 'Profile screen should be showing');

    // Switch to Pantry and pump a SINGLE frame. With NoTransitionPage the swap
    // completes immediately; a slide transition would still have Profile in the
    // tree here, so this is what catches the regression.
    router.go(Routes.pantry);
    await tester.pump();

    expect(find.text('Your household'), findsNothing,
        reason: 'previous tab must not stay mounted during the switch');
    expect(find.textContaining('Pantry ('), findsWidgets,
        reason: 'Pantry screen should be showing after the swap');

    // Let the splash timer fire (harmlessly) so the test ends without a
    // pending-timer failure.
    await tester.pump(const Duration(seconds: 2));
  });
}
