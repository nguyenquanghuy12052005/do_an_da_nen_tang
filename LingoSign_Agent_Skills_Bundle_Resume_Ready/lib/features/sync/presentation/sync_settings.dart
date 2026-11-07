import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_components.dart';
import '../../../app/sync_providers.dart';
import '../../../app/firebase_session.dart';

class SyncSettings extends ConsumerStatefulWidget {
  const SyncSettings({super.key});
  @override
  ConsumerState<SyncSettings> createState() => _SyncSettingsState();
}

class _SyncSettingsState extends ConsumerState<SyncSettings> {
  bool? _enabled;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (ref.read(syncConfiguredProvider)) _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await ref.read(syncRepositoryProvider).isEnabled();
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không đọc được cài đặt đồng bộ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = ref.watch(firebaseSessionProvider);
    if (!ref.watch(syncConfiguredProvider)) {
      if (firebase != null) {
        return const ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text("Đồng bộ tài khoản"),
          subtitle: Text("Đăng nhập để bật đồng bộ Firebase."),
        );
      }
      return const ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text('Đồng bộ lịch sử'),
        subtitle: Text('Chưa cấu hình máy chủ đồng bộ cho bản chạy này.'),
      );
    }
    final count = ref.watch(pendingSyncCountProvider).asData?.value;
    final result = ref.watch(syncControllerProvider);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          secondary: AccentIcon(
            Icons.cloud_outlined,
            accent: AppAccents.colors[4],
          ),
          title: Text(
            firebase == null ? 'Đồng bộ lịch sử' : 'Đồng bộ lịch sử và tiến độ',
          ),
          subtitle: Text(
            firebase != null
                ? 'Ảnh chỉ lưu trên thiết bị.'
                : 'Các thiết bị cùng mã kết nối chia sẻ lịch sử.',
          ),
          value: _enabled ?? false,
          onChanged: _enabled == null || _busy
              ? null
              : (enabled) async {
                  setState(() => _busy = true);
                  try {
                    await ref.read(syncRepositoryProvider).setEnabled(enabled);
                    if (mounted) {
                      setState(() {
                        _enabled = enabled;
                        _error = null;
                      });
                    }
                    if (enabled) {
                      await ref
                          .read(syncControllerProvider.notifier)
                          .synchronize();
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => _error = 'Không lưu được cài đặt đồng bộ.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          title: Text('Đang chờ đồng bộ: ${count ?? '…'}'),
          subtitle: Text(
            _error ??
                result.asData?.value?.error ??
                (result.hasError
                    ? 'Đồng bộ gặp lỗi, sẽ thử lại.'
                    : 'Tự đồng bộ khi có mạng.'),
          ),
          trailing: IconButton(
            tooltip: 'Đồng bộ ngay',
            onPressed: _enabled == true && !_busy
                ? () => ref.read(syncControllerProvider.notifier).synchronize()
                : null,
            icon: const Icon(Icons.sync),
          ),
        ),
      ],
    );
  }
}
