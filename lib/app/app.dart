import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/ember_theme.dart';

class LoopServeApp extends ConsumerWidget {
  const LoopServeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LoopServe 3.0 — Advanced Restaurant Operations',
      debugShowCheckedModeBanner: false,
      theme: EmberTheme.darkTheme,
      darkTheme: EmberTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
