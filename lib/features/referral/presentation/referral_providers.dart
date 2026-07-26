import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/referral_repository.dart';
import '../domain/referral_models.dart';

final referralRepositoryProvider = Provider<ReferralRepository>(
    (ref) => ReferralRepository(ref.watch(apiClientProvider)));

final referralInfoProvider = FutureProvider<ReferralInfo>(
    (ref) => ref.watch(referralRepositoryProvider).code());
