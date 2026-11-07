import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
    required this.canLearn,
  });

  final String location;
  final Widget child;
  final bool canLearn;

  static const _paths = [
    '/',
    '/dictionary',
    '/history',
    '/learning',
    '/settings',
  ];
  static const _titles = [
    'Nhận diện',
    'Từ điển',
    'Lịch sử',
    'Học tập',
    'Cài đặt',
  ];

  @override
  Widget build(BuildContext context) {
    final index = _paths.indexOf(location);
    final selectedIndex = index < 0 ? 0 : index;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: scheme.onSurface,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sign_language_outlined,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        title: const Text(
          'LingoSign',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              _titles[selectedIndex],
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(location),
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,

          onDestinationSelected: (value) => context.go(_paths[value]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.sign_language_outlined),
              label: 'Nhận diện',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: 'Từ điển',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_rounded),
              label: 'Lịch sử',
            ),
            NavigationDestination(
              enabled: canLearn,
              icon: canLearn
                  ? const Icon(Icons.school_outlined)
                  : const Icon(Icons.lock_outline),
              label: 'Học tập',
              tooltip: canLearn
                  ? null
                  : 'Đăng nhập trong Cài đặt để mở Học tập',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}
