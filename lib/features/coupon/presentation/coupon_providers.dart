import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/coupon_repository.dart';
import '../domain/coupon_models.dart';

final couponRepositoryProvider = Provider<CouponRepository>(
    (ref) => CouponRepository(ref.watch(apiClientProvider)));

final couponsProvider = FutureProvider<List<Coupon>>(
    (ref) => ref.watch(couponRepositoryProvider).list());
