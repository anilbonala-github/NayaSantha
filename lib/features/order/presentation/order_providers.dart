import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
    (ref) => OrderRepository(ref.watch(apiClientProvider)));

/// Order history list (Vol2 §6.8).
final ordersProvider = FutureProvider<List<CustomerOrder>>(
    (ref) => ref.watch(orderRepositoryProvider).list());

/// A single order by id (used by the final-bill / tracking screens).
final orderProvider = FutureProvider.family<CustomerOrder, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).get(id));
