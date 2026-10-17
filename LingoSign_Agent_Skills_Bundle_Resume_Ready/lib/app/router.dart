import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lingosign_ai/app/shell.dart';
import 'package:lingosign_ai/features/home/presentation/home_page.dart';
import 'package:lingosign_ai/features/dictionary/presentation/dictionary_page.dart';
import 'package:lingosign_ai/features/history/presentation/history_page.dart';
import 'package:lingosign_ai/features/settings/presentation/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/dictionary',
            builder: (context, state) => const DictionaryPage(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
