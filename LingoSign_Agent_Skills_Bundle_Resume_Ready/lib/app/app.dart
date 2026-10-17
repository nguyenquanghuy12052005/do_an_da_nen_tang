import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/router.dart';
import 'package:lingosign_ai/app/theme/app_theme.dart';
import 'package:lingosign_ai/app/theme/theme_mode_controller.dart';

class LingoSignApp extends ConsumerWidget {
  const LingoSignApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LingoSign AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
