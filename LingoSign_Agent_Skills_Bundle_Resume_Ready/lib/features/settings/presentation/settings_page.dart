import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/theme/theme_mode_controller.dart';

import '../../sync/presentation/sync_settings.dart';
import '../../../app/design_components.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeading(
          title: 'Theo cách của bạn',
          subtitle: 'Tùy chỉnh giao diện và quản lý đồng bộ lịch sử.',
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SyncSettings(),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Chế độ tối'),
            subtitle: const Text('Chỉ áp dụng trong phiên sử dụng này'),
            value: isDark,
            onChanged: ref.read(themeModeProvider.notifier).setDarkMode,
          ),
        ),
      ],
    );
  }
}
