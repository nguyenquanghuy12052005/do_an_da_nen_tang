import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/firebase_session.dart';
import '../../../app/local_data_providers.dart';
import '../data/admin_providers.dart';
import '../domain/account_access.dart';

class StoredRecordsPage extends ConsumerStatefulWidget {
  const StoredRecordsPage({super.key, required this.local});
  final bool local;
  @override
  ConsumerState<StoredRecordsPage> createState() => _StoredRecordsPageState();
}

class _StoredRecordsPageState extends ConsumerState<StoredRecordsPage> {
  final _uid = TextEditingController();
  String? _selectedUid;
  String? _error;
  bool _busy = false;
  List<Map<String, dynamic>> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  @override
  void initState() {
    super.initState();
    _selectedUid = ref.read(firebaseSessionProvider)?.user?.uid;
    _uid.text = _selectedUid ?? '';
    _load();
  }

  @override
  void dispose() {
    _uid.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = <Map<String, dynamic>>[];
      if (widget.local) {
        final repository = ref.read(historyRepositoryProvider);
        final records = await repository.watchHistory().first;
        for (final record in records) {
          items.add({
            'id': record.id,
            'summary': record.label,
            'note': record.note,
            'at': record.confirmedAt.toLocal().toString(),
          });
        }
      } else {
        final session = ref.read(firebaseSessionProvider)!;
        final uid = _selectedUid;
        if (uid == null || uid.isEmpty || uid.contains('/')) {
          throw StateError('UID');
        }
        Query<Map<String, dynamic>> query = session.firestore
            .collection('users')
            .doc(uid)
            .collection('syncEvents')
            .orderBy(FieldPath.documentId)
            .limit(30);
        if (more && _cursor != null) query = query.startAfterDocument(_cursor!);
        final page = await query.get(const GetOptions(source: Source.server));
        _cursor = page.size == 30 ? page.docs.last : null;
        for (final doc in page.docs) {
          items.add({
            ...doc.data(),
            'id': doc.id,
            'at': (doc.data()['occurredAt'] ?? doc.data()['committedAt'])
                .toString(),
          });
        }
      }
      if (mounted) setState(() => _items = [if (more) ..._items, ...items]);
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'Không đọc được lịch sử. Kiểm tra UID, mạng và quyền.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final controller = TextEditingController(
      text: widget.local ? item['note'] as String? : item['summary'] as String?,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.local ? 'Ghi chú đánh giá' : 'Sửa mô tả sự kiện'),
        content: TextField(controller: controller, maxLength: 256),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await _change(() async {
      if (widget.local) {
        await ref
            .read(historyRepositoryProvider)
            .updateReview(item['id'] as String, note: result);
      } else {
        await ref
            .read(firebaseSessionProvider)!
            .firestore
            .collection('users')
            .doc(_selectedUid)
            .collection('syncEvents')
            .doc(item['id'] as String)
            .update({'summary': result});
      }
    });
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bản ghi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _change(() async {
      if (widget.local) {
        await ref.read(historyRepositoryProvider).delete(item['id'] as String);
      } else {
        await ref
            .read(firebaseSessionProvider)!
            .firestore
            .collection('users')
            .doc(_selectedUid)
            .collection('syncEvents')
            .doc(item['id'] as String)
            .delete();
      }
    });
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on Exception {
      if (mounted) setState(() => _error = 'Không lưu được thay đổi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accountAccessProvider).value;
    final allowed =
        access?.isStaff == true &&
        (widget.local || access?.role == AccountRole.admin);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.local ? 'Lịch sử SQLite' : 'Lịch sử Firebase'),
      ),
      body: !allowed
          ? const Center(child: Text('Không đủ quyền.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!widget.local)
                  TextField(
                    controller: _uid,
                    decoration: InputDecoration(
                      labelText: 'UID người dùng',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _busy
                            ? null
                            : () {
                                _selectedUid = _uid.text.trim();
                                _cursor = null;
                                _load();
                              },
                      ),
                    ),
                  ),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) Text(_error!),
                if (!_busy && _items.isEmpty) const Text('Chưa có bản ghi.'),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      title: Text(
                        item['summary'] as String? ?? item['id'] as String,
                      ),
                      subtitle: Text('${item['at']}'),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Chi tiết'),
                          scrollable: true,
                          content: SelectableText(item.toString()),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: _busy ? null : () => _edit(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _busy ? null : () => _delete(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!widget.local && _cursor != null)
                  TextButton(
                    onPressed: _busy ? null : () => _load(more: true),
                    child: const Text('Tải thêm'),
                  ),
              ],
            ),
    );
  }
}
