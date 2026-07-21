import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/address_repository.dart';
import '../domain/address_models.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
    (ref) => AddressRepository(ref.watch(apiClientProvider)));

final addressesProvider = FutureProvider<List<Address>>(
    (ref) => ref.watch(addressRepositoryProvider).list());
