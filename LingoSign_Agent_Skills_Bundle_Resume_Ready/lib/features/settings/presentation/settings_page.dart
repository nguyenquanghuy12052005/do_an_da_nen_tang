import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/theme/theme_mode_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Chế độ tối'),
          subtitle: const Text('Chỉ áp dụng trong phiên sử dụng này'),
          value: isDark,
          onChanged: ref.read(themeModeProvider.notifier).setDarkMode,
        ),
      ],
    );
  }
}
