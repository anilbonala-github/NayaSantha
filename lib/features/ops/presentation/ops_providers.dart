import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/ops_repository.dart';
import '../domain/ops_models.dart';

final opsRepositoryProvider = Provider<OpsRepository>(
    (ref) => OpsRepository(ref.watch(apiClientProvider)));

/// Cutoff snapshot for the ops dashboard.
final opsSummaryProvider = FutureProvider.autoDispose<OpsSummary>(
    (ref) => ref.watch(opsRepositoryProvider).summary());

/// Consolidated buy list across all locked orders.
final purchaseListProvider = FutureProvider.autoDispose<List<PurchaseLine>>(
    (ref) => ref.watch(opsRepositoryProvider).purchaseList());
