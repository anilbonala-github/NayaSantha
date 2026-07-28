import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/push/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'state/app_state.dart';
import 'state/assistant_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Initialise Firebase (no permission prompt yet); a no-op if not configured.
  await FcmService.init();
  // ProviderScope enables Riverpod (backend-backed features, Vol2 §2).
  // The legacy `provider` graph still runs for not-yet-migrated screens.
  runApp(const ProviderScope(child: NayaSanthaApp()));
}

class NayaSanthaApp extends ConsumerStatefulWidget {
  const NayaSanthaApp({super.key});

  @override
  ConsumerState<NayaSanthaApp> createState() => _NayaSanthaAppState();
}

class _NayaSanthaAppState extends ConsumerState<NayaSanthaApp> {
  final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    // Returning users already have a session — register their push token now.
    Future.microtask(() async {
      final access = await ref.read(tokenStoreProvider).readAccess();
      if (access != null && access.isNotEmpty) {
        await FcmService.registerToken(ref.read(apiClientProvider));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Register the push token on fresh login; unregister on logout.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        FcmService.registerToken(ref.read(apiClientProvider));
      } else if (next is AuthInitial && prev is AuthAuthenticated) {
        FcmService.unregister(ref.read(apiClientProvider));
      }
    });
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        ChangeNotifierProvider<AssistantState>(create: (_) => AssistantState()),
      ],
      child: MaterialApp.router(
        title: 'NayaSantha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
