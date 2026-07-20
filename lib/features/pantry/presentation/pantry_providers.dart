import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/pantry_repository.dart';
import '../domain/pantry_models.dart';

final pantryRepositoryProvider = Provider<PantryRepository>(
    (ref) => PantryRepository(ref.watch(apiClientProvider)));

/// The household pantry as async state (Vol2 §6.4/§9).
class PantryNotifier extends AsyncNotifier<List<PantryItem>> {
  PantryRepository get _repo => ref.read(pantryRepositoryProvider);

  @override
  Future<List<PantryItem>> build() => _repo.list();

  Future<void> add({
    required String name,
    required double quantity,
    String? unit,
    String? productId,
    String? expiryDate,
  }) async {
    await _repo.add(
      name: name,
      quantity: quantity,
      unit: unit,
      productId: productId,
      expiryDate: expiryDate,
    );
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> setQuantity(PantryItem item, double quantity) async {
    await _repo.updateQuantity(
        id: item.id, name: item.name, quantity: quantity, version: item.version);
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = await AsyncValue.guard(_repo.list);
  }
}

final pantryProvider =
    AsyncNotifierProvider<PantryNotifier, List<PantryItem>>(PantryNotifier.new);

/// Items that are low or expiring — the "smart suggestions" view (Vol2 §6.4).
final pantrySuggestionsProvider = Provider<List<PantryItem>>((ref) =>
    ref.watch(pantryProvider).maybeWhen(
        data: (items) => items.where((i) => i.needsAttention).toList(),
        orElse: () => const <PantryItem>[]));
