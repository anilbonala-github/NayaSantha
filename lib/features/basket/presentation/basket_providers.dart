import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/basket_repository.dart';
import '../domain/basket_models.dart';

final basketRepositoryProvider = Provider<BasketRepository>(
    (ref) => BasketRepository(ref.watch(apiClientProvider)));

/// The current basket as an async state (loading/data/error, Vol2 §9).
/// Mutations optimistically await the server's recalculated basket.
class BasketNotifier extends AsyncNotifier<Basket> {
  BasketRepository get _repo => ref.read(basketRepositoryProvider);

  @override
  Future<Basket> build() => _repo.current();

  Future<void> add(String productId, {int quantity = 1}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.addItem(productId, quantity: quantity));
  }

  Future<void> setQuantity(String itemId, int quantity, {int? version}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.updateItem(itemId, quantity: quantity, version: version));
  }

  Future<void> remove(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.removeItem(itemId));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.current);
  }
}

final basketProvider =
    AsyncNotifierProvider<BasketNotifier, Basket>(BasketNotifier.new);

/// Convenience: current basket item count for the nav badge (0 while loading).
final basketCountProvider = Provider<int>((ref) =>
    ref.watch(basketProvider).maybeWhen(data: (b) => b.itemCount, orElse: () => 0));
