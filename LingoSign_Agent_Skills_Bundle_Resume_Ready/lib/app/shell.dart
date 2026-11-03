import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design_components.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _paths = [
    '/',
    '/dictionary',
    '/history',
    '/settings',
    '/learning',
  ];
  static const _titles = [
    'Nhận diện',
    'Từ điển',
    'Lịch sử',
    'Cài đặt',
    'Học tập',
  ];

  @override
  Widget build(BuildContext context) {
    final index = _paths.indexOf(location);
    final selectedIndex = index < 0 ? 0 : index;
    final accent = AppAccents.colors[selectedIndex];
    return Scaffold(
      backgroundColor: AppAccents.tint(context, accent),
      appBar: AppBar(
        foregroundColor: Colors.white,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                Color.lerp(accent, const Color(0xFF21284F), .35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sign_language_outlined,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                  ?.copyWith(color: Colors.white),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        indicatorColor: AppAccents.tint(context, accent),
        onDestinationSelected: (value) => context.go(_paths[value]),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.sign_language, color: AppAccents.colors[0]),
            label: 'Nhận diện',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book, color: AppAccents.colors[1]),
            label: 'Từ điển',
          ),
          NavigationDestination(
            icon: Icon(Icons.history, color: AppAccents.colors[2]),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: AppAccents.colors[3]),
            label: 'Cài đặt',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: AppAccents.colors[4]),
            label: 'Học tập',
          ),
        ],
      ),
    );
  }
}
