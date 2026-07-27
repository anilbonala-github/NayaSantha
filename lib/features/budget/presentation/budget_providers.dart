import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/budget_repository.dart';
import '../domain/budget_models.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
    (ref) => BudgetRepository(ref.watch(apiClientProvider)));

final budgetInsightsProvider = FutureProvider<BudgetInsights>(
    (ref) => ref.watch(budgetRepositoryProvider).get());
