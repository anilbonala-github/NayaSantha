import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_models.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
    (ref) => SubscriptionRepository(ref.watch(apiClientProvider)));

final membershipPlansProvider = FutureProvider<List<MembershipPlan>>(
    (ref) => ref.watch(subscriptionRepositoryProvider).plans());

final currentSubscriptionProvider = FutureProvider<CurrentSubscription?>(
    (ref) => ref.watch(subscriptionRepositoryProvider).current());
