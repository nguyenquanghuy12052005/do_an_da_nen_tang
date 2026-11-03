import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/sync_providers.dart';

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
    if (!ref.watch(syncConfiguredProvider)) {
      return const ListTile(
        title: Text('Đồng bộ lịch sử'),
        subtitle: Text('Chưa cấu hình máy chủ đồng bộ cho bản chạy này.'),
      );
    }
    final count = ref.watch(pendingSyncCountProvider).asData?.value;
    final result = ref.watch(syncControllerProvider);
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Đồng bộ lịch sử'),
          subtitle: const Text(
            'Gửi nhãn, thời gian và thao tác xóa đến máy chủ đã cấu hình. Ảnh chỉ lưu trên thiết bị. Các thiết bị dùng cùng mã kết nối sẽ chia sẻ lịch sử.',
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
        ListTile(
          title: Text('Đang chờ đồng bộ: ${count ?? '…'}'),
          subtitle: Text(
            _error ??
                result.asData?.value?.error ??
                (result.hasError
                    ? 'Đồng bộ gặp lỗi, sẽ thử lại.'
                    : 'Tự thử mỗi 5 giây khi app đang mở. Lỗi kết nối sẽ tăng thời gian chờ, tối đa 5 phút.'),
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
