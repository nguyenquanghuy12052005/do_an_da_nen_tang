import 'firebase_session.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../features/learning/presentation/practice_page.dart';
import '../features/learning/presentation/learning_page.dart';

import 'package:go_router/go_router.dart';
import 'package:lingosign_ai/app/shell.dart';
import 'package:lingosign_ai/features/home/presentation/home_page.dart';
import 'package:lingosign_ai/features/dictionary/presentation/dictionary_page.dart';
import 'package:lingosign_ai/features/history/presentation/history_page.dart';
import 'package:lingosign_ai/features/settings/presentation/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final canLearn = ref.watch(firebaseSessionProvider)?.user != null;
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      return !canLearn && (path == '/learning' || path == '/practice')
          ? '/settings'
          : null;
    },
    routes: [
      GoRoute(
        path: '/practice',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Luyện tập')),
          body: SafeArea(
            child: PracticePage(target: state.uri.queryParameters['target']),
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.path,
          canLearn: canLearn,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/learning',
            builder: (context, state) => const LearningPage(),
          ),
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
