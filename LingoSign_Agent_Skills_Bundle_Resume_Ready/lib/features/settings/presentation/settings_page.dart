import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/theme/theme_mode_controller.dart';

import '../../sync/presentation/sync_settings.dart';
import '../../account/presentation/account_settings.dart';
import '../../../app/design_components.dart';
import '../../../app/firebase_session.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFirebase = ref.watch(firebaseSessionProvider) != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const SectionHeading(
          title: 'Theo cách của bạn',
          accent: Color(0xFF49619C),
          icon: Icons.tune_rounded,
          subtitle: 'Tài khoản, đồng bộ và giao diện',
          margin: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        if (hasFirebase) ...[
          const PanelHeading('Tài khoản'),
          const AccountSettings(),
          const SizedBox(height: 24),
        ],
        const PanelHeading('Đồng bộ'),
        const Card(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SyncSettings(),
          ),
        ),
        const SizedBox(height: 24),
        const PanelHeading('Giao diện'),
        Card(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            secondary: AccentIcon(
              Icons.dark_mode_outlined,
              accent: AppAccents.colors[0],
            ),
            title: const Text('Chế độ tối'),
            value: isDark,
            onChanged: ref.read(themeModeProvider.notifier).setDarkMode,
          ),
        ),
      ],
    );
  }
}
