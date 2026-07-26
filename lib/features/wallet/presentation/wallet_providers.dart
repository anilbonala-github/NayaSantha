import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
    (ref) => WalletRepository(ref.watch(apiClientProvider)));

final walletProvider = FutureProvider<Wallet>(
    (ref) => ref.watch(walletRepositoryProvider).get());
