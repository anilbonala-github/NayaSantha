import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepository(ref.watch(apiClientProvider)));

final profileProvider = FutureProvider<Profile>(
    (ref) => ref.watch(profileRepositoryProvider).getProfile());

final householdProvider = FutureProvider<Household>(
    (ref) => ref.watch(profileRepositoryProvider).getHousehold());
