import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naya_santha/core/api/api_client.dart';
import 'package:naya_santha/core/api/api_failure.dart';
import 'package:naya_santha/core/api/token_store.dart';
import 'package:naya_santha/core/theme/app_theme.dart';
import 'package:naya_santha/features/basket/data/basket_repository.dart';
import 'package:naya_santha/features/basket/domain/checkout_preview.dart';
import 'package:naya_santha/features/basket/presentation/basket_providers.dart';
import 'package:naya_santha/features/basket/presentation/checkout_screen.dart';
import 'package:naya_santha/features/order/domain/order_models.dart';

class CheckoutRepo extends BasketRepository {
  CheckoutRepo() : super(ApiClient(tokenStore: TokenStore()));
  bool failPreview = false, failConfirm = false;
  bool rejectReview = false;
  int confirmations = 0, previews = 0;
  final submitted = <CheckoutPreview>[];
  CheckoutPreview review = const CheckoutPreview(
      basketId: 'real-basket',
      quoteToken: 'review-token',
      items: [
        CheckoutLine(
            name: 'Rice',
            unit: '1 kg',
            quantity: 2,
            unitPrice: 75.5,
            amount: 151)
      ],
      subtotal: 151,
      deliveryFee: 39,
      total: 190,
      deliveryAddress: 'Saved apartment, Hyderabad',
      deliverySlot: 'Sunday morning');
  @override
  Future<CheckoutPreview> checkoutPreview() async {
    previews++;
    if (failPreview)
      throw const ApiFailure(
          errorCode: 'VALIDATION_ERROR',
          userMessage:
              'Choose a serviceable delivery address before checkout.');
    return review;
  }

  @override
  Future<CustomerOrder> checkout(CheckoutPreview preview) async {
    confirmations++;
    submitted.add(preview);
    if (rejectReview) {
      throw const ApiFailure(
          errorCode: 'VALIDATION_ERROR',
          userMessage: 'Prices changed. Refresh the review before confirming.');
    }
    if (failConfirm)
      throw const ApiFailure(
          errorCode: 'OFFLINE',
          userMessage: 'Connection interrupted. Please retry.');
    return const CustomerOrder(
        id: 'persisted-order',
        status: 'CONFIRMED',
        pricePreference: 'KEEP_EXACT_ITEMS',
        pricingMode: 'FIXED_WEEKLY',
        estimatedTotal: 151,
        maximumPayable: 151,
        finalTotal: 151);
  }
}

void main() {
  Future<void> show(WidgetTester tester, CheckoutRepo repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/checkout', routes: [
      GoRoute(
          path: '/checkout', builder: (_, __) => const BasketCheckoutScreen()),
      GoRoute(
          path: '/order/:id',
          builder: (_, s) =>
              Scaffold(body: Text('Order ${s.pathParameters['id']}'))),
      GoRoute(
          path: '/onboarding/address',
          builder: (_, s) => Scaffold(
              body: Text('Address return ${s.uri.queryParameters['from']}'))),
      GoRoute(
          path: '/basket',
          builder: (_, __) => const Scaffold(body: Text('Basket'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [basketRepositoryProvider.overrideWithValue(repo)],
        child:
            MaterialApp.router(theme: AppTheme.light(), routerConfig: router)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'review shows saved address and fee before creating a persisted order',
      (tester) async {
    final repo = CheckoutRepo();
    await show(tester, repo);
    expect(find.text('Saved apartment, Hyderabad'), findsOneWidget);
    expect(find.text('₹39.00'), findsOneWidget);
    expect(find.text('Confirm order · ₹190.00').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Confirm order · ₹190.00'));
    await tester.pumpAndSettle();
    expect(find.text('Order persisted-order'), findsOneWidget);
    expect(repo.submitted.single.basketId, 'real-basket');
    expect(repo.submitted.single.quoteToken, 'review-token');
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed confirmation keeps the reviewed basket for safe retry',
      (tester) async {
    final repo = CheckoutRepo()..failConfirm = true;
    await show(tester, repo);
    await tester.tap(find.text('Confirm order · ₹190.00'));
    await tester.pumpAndSettle();
    expect(find.text('Connection interrupted. Please retry.'), findsOneWidget);
    repo.failConfirm = false;
    await tester.tap(find.text('Confirm order · ₹190.00'));
    await tester.pumpAndSettle();
    expect(repo.confirmations, 2);
    expect(repo.previews, 1);
    expect(repo.submitted[0].quoteToken, repo.submitted[1].quoteToken);
    expect(find.text('Order persisted-order'), findsOneWidget);
  });
  testWidgets('failed refresh removes the old confirmation action',
      (tester) async {
    final repo = CheckoutRepo()..failConfirm = true;
    await show(tester, repo);
    await tester.tap(find.text('Confirm order · ₹190.00'));
    await tester.pumpAndSettle();
    repo.failPreview = true;
    await tester.tap(find.text('Refresh review'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm order · ₹190.00'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Review required'))
            .onPressed,
        isNull);
    expect(repo.confirmations, 1);
  });
  testWidgets('rejected review requires refresh before another confirmation',
      (tester) async {
    final repo = CheckoutRepo()..rejectReview = true;
    await show(tester, repo);
    await tester.tap(find.text('Confirm order · ₹190.00'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm order · ₹190.00'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Review required'))
            .onPressed,
        isNull);
    repo.rejectReview = false;
    repo.review = const CheckoutPreview(
        basketId: 'real-basket',
        quoteToken: 'updated-token',
        items: [],
        subtotal: 160,
        deliveryFee: 39,
        total: 199,
        deliveryAddress: 'Saved apartment, Hyderabad');
    await tester.tap(find.text('Refresh review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm order · ₹199.00'));
    await tester.pumpAndSettle();
    expect(repo.submitted.last.quoteToken, 'updated-token');
    expect(find.text('Order persisted-order'), findsOneWidget);
  });
  testWidgets(
      'missing serviceable address prevents checkout and offers address editing',
      (tester) async {
    final repo = CheckoutRepo()..failPreview = true;
    await show(tester, repo);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Review required'))
            .onPressed,
        isNull);
    await tester.tap(find.text('Change delivery address'));
    await tester.pumpAndSettle();
    expect(find.text('Address return checkout'), findsOneWidget);
    expect(repo.confirmations, 0);
  });
}
