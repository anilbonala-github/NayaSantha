import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya_santha/core/api/api_client.dart';
import 'package:naya_santha/core/api/token_store.dart';
import 'package:naya_santha/core/theme/app_theme.dart';
import 'package:naya_santha/features/order/data/order_repository.dart';
import 'package:naya_santha/features/order/domain/order_models.dart';
import 'package:naya_santha/features/order/presentation/order_bill_screen.dart';
import 'package:naya_santha/features/order/presentation/order_providers.dart';
import 'package:naya_santha/features/plan/domain/plan_models.dart';
import 'package:naya_santha/features/plan/presentation/plan_providers.dart';
import 'package:naya_santha/features/plan/presentation/weekly_plan_screen.dart';

class ReviewPlan extends WeeklyPlanNotifier {
  ReviewPlan(this.mode);
  final String mode;
  @override
  Future<WeeklyPlan?> build() async => WeeklyPlan(
        id: 'plan',
        weekStart: '2026-09-20',
        status: 'DRAFT',
        aiSource: 'FALLBACK',
        estimatedTotal: 151,
        maximumPayable: 151,
        itemCount: 2,
        version: 2,
        pricingMode: mode,
        items: const [
          PlanItem(
              id: 'line',
              productId: 'rice',
              name: 'Rice',
              unit: '1 kg',
              quantity: 2,
              lineEstimate: 151,
              lineMax: 151)
        ],
      );
}

class ReviewOrderRepository extends OrderRepository {
  ReviewOrderRepository() : super(ApiClient(tokenStore: TokenStore()));
  @override
  Future<CustomerOrder> get(String id) async => CustomerOrder(
        id: id,
        status: 'CONFIRMED',
        pricePreference: 'KEEP_EXACT_ITEMS',
        pricingMode: 'FIXED_WEEKLY',
        estimatedTotal: 151,
        maximumPayable: 151,
        finalTotal: 151,
        deliveryFee: 39,
        amountPayable: 190,
        gatewayPayable: 190,
        items: const [
          OrderLine(
              id: 'line',
              name: 'Rice',
              unit: '1 kg',
              quantity: 2,
              forecastRate: 75.50,
              estimatedAmount: 151,
              actualRate: 75.50,
              finalAmount: 151)
        ],
      );
}

void main() {
  Future<void> show(WidgetTester tester, Widget screen,
      {String mode = 'FIXED_WEEKLY'}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(overrides: [
      weeklyPlanProvider.overrideWith(() => ReviewPlan(mode)),
      orderRepositoryProvider.overrideWithValue(ReviewOrderRepository()),
    ], child: MaterialApp(theme: AppTheme.light(), home: screen)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'fixed plan shows subtotal and review action without variable-price consent',
      (tester) async {
    await show(tester, const AiWeeklyPlanScreen());
    expect(find.text('Item subtotal'), findsOneWidget);
    expect(find.text('Add plan to basket').hitTestable(), findsOneWidget);
    expect(find.textContaining('Guaranteed maximum'), findsNothing);
    await tester.tap(find.text('Add plan to basket'));
    await tester.pumpAndSettle();
    expect(find.text('Item subtotal: ₹151.00'), findsOneWidget);
    expect(find.text('Add items').hitTestable(), findsOneWidget);
    expect(find.textContaining('Smart substitute'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('legacy plan must be regenerated before fixed-price confirmation',
      (tester) async {
    await show(tester, const AiWeeklyPlanScreen(), mode: 'LEGACY_VARIABLE');
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add plan to basket'));
    expect(button.onPressed, isNull);
    expect(find.textContaining('older plan'), findsOneWidget);
  });
  testWidgets('fixed order shows exact money and no market simulation',
      (tester) async {
    await show(tester, const OrderBillScreen(orderId: 'order'));
    expect(find.text('Confirmed item subtotal'), findsOneWidget);
    expect(find.text('₹190.00'), findsOneWidget);
    expect(find.textContaining('Run Sunday settlement'), findsNothing);
    expect(find.text('Estimate vs actual'), findsNothing);
    expect(find.textContaining('₹75.50 each'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('old order payloads retain legacy pricing mode', () {
    final order = CustomerOrder.fromJson({
      'id': 'old',
      'status': 'LOCKED',
      'pricePreference': 'KEEP_EXACT_ITEMS'
    });
    expect(order.isFixedPrice, isFalse);
  });
}
