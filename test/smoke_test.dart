import 'package:flutter_test/flutter_test.dart';
import 'package:naya_santha/data/mock_data.dart';
import 'package:naya_santha/data/models.dart';
import 'package:naya_santha/state/app_state.dart';

void main() {
  test('basket totals and free-delivery threshold', () {
    final AppState app = AppState();
    app.addToBasket(MockData.byId('p_tomato'), quantity: 2);
    expect(app.basketCount, 2);
    expect(app.basketSubtotal, 80);
    expect(app.deliveryFee, 39); // under the free-delivery threshold

    app.addToBasket(MockData.byId('p_atta'), quantity: 3);
    expect(app.basketSubtotal, 80 + 735);
    expect(app.deliveryFee, 0); // over threshold
  });

  test('removing a line by setting quantity to zero', () {
    final AppState app = AppState();
    app.addToBasket(MockData.byId('p_milk'), quantity: 3);
    app.setBasketQuantity('p_milk', 0);
    expect(app.basket, isEmpty);
  });

  test('generated plan stays within the household budget', () async {
    final AppState app = AppState();
    await app.generatePlan();
    final WeeklyPlan plan = app.plan!;
    expect(plan.lines, isNotEmpty);
    expect(plan.estimatedCost, lessThan(app.weeklyBudget));
  });

  test('pantry flags items that are low or expiring', () {
    final AppState app = AppState();
    final List<PantryItem> flagged =
        app.pantry.where((PantryItem p) => p.needsAttention).toList();
    expect(flagged, isNotEmpty);
    // Atta is seeded as low stock even though it is nowhere near expiry.
    expect(
      flagged.any((PantryItem p) => p.product.id == 'p_atta'),
      isTrue,
    );
  });

  test('rated products expose a rating and a review count', () {
    final Product tomato = MockData.byId('p_tomato');
    expect(tomato.rating, 4.6);
    expect(tomato.ratingCount, greaterThan(0));
    expect(tomato.badges, contains('Farm Fresh'));
  });

  test('placing an order clears the basket and records history', () async {
    final AppState app = AppState();
    app.addToBasket(MockData.byId('p_rice'), quantity: 2);
    final int before = app.orders.length;
    final Order order = await app.placeOrder(paymentMethod: 'UPI');
    expect(app.basket, isEmpty);
    expect(app.orders.length, before + 1);
    expect(order.itemCount, 2);
  });
}
