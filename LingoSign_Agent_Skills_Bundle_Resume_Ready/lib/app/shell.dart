import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _paths = ['/', '/dictionary', '/history', '/settings'];
  static const _titles = ['Nhận diện', 'Từ điển', 'Lịch sử', 'Cài đặt'];

  @override
  Widget build(BuildContext context) {
    final index = _paths.indexOf(location);
    final selectedIndex = index < 0 ? 0 : index;
    return Scaffold(
      appBar: AppBar(title: Text(_titles[selectedIndex])),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) => context.go(_paths[value]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sign_language),
            label: 'Nhận diện',
          ),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Từ điển'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
