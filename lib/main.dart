import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/app_state.dart';
import 'state/assistant_state.dart';

void main() {
  usePathUrlStrategy();
  runApp(const NayaSanthaApp());
}

class NayaSanthaApp extends StatefulWidget {
  const NayaSanthaApp({super.key});

  @override
  State<NayaSanthaApp> createState() => _NayaSanthaAppState();
}

class _NayaSanthaAppState extends State<NayaSanthaApp> {
  final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
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
