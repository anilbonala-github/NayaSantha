import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/plan_repository.dart';
import '../domain/plan_models.dart';

final planRepositoryProvider = Provider<PlanRepository>(
    (ref) => PlanRepository(ref.watch(apiClientProvider)));

/// The current weekly plan (null until one is generated). Vol2 §6.5/§9.
class WeeklyPlanNotifier extends AsyncNotifier<WeeklyPlan?> {
  PlanRepository get _repo => ref.read(planRepositoryProvider);

  @override
  Future<WeeklyPlan?> build() => _repo.current();

  Future<void> generate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.generate);
  }

  Future<void> setItemQuantity(String itemId, int quantity, {int? version}) async {
    final plan = state.valueOrNull;
    if (plan == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.setItemQuantity(plan.id, itemId, quantity, version: version));
  }
}

final weeklyPlanProvider =
    AsyncNotifierProvider<WeeklyPlanNotifier, WeeklyPlan?>(WeeklyPlanNotifier.new);
