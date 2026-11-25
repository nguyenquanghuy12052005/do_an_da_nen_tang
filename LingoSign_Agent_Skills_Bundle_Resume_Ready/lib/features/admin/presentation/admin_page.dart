import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_components.dart';
import '../../../app/local_data_providers.dart';
import '../data/admin_providers.dart';
import '../data/firebase_admin_gateway.dart';
import '../domain/account_access.dart';
import '../domain/user_presence.dart';
import 'stored_records_page.dart';

const _sections = [
  ('overview', 'Tổng quan', Icons.dashboard_outlined),
  ('users', 'Người dùng', Icons.people_outline),
  ('signs', 'Ký hiệu', Icons.sign_language_outlined),
  ('categories', 'Danh mục', Icons.category_outlined),
  ('lessons', 'Bài học', Icons.school_outlined),
  ('audit', 'Nhật ký', Icons.receipt_long_outlined),
];

String _message(Object error) => error is AdminFailure
    ? error.message
    : 'Không tải được dữ liệu quản trị. Hãy thử lại.';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  String _section = 'users';
  bool _local = false;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accountAccessProvider);
    final account = access.asData?.value;
    final isAdmin = account?.role == AccountRole.admin;
    final sections = _sections
        .where(
          (section) =>
              (isAdmin || !['users', 'audit'].contains(section.$1)) &&
              (!_local || section.$1 != 'users'),
        )
        .toList();
    final selected = sections.any((section) => section.$1 == _section)
        ? _section
        : 'overview';
    final cloudGateway = ref.watch(adminGatewayProvider);
    final gateway = cloudGateway == null
        ? null
        : _local
        ? FirebaseAdminGateway(
            cloudGateway.session,
            database: ref.watch(appDatabaseProvider),
          )
        : cloudGateway;
    return Scaffold(
      appBar: AppBar(title: const Text('Khu vực quản trị')),
      body: SafeArea(
        child: access.isLoading
            ? const Center(child: CircularProgressIndicator())
            : account?.isStaff != true || gateway == null
            ? const Center(
                child: Text('Không có quyền quản trị hoặc chưa kết nối.'),
              )
            : Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dữ liệu SQLite trên thiết bị'),
                    subtitle: Text(
                      _local
                          ? 'Chỉnh sửa nội dung cục bộ'
                          : 'Đang quản lý Firebase',
                    ),
                    value: _local,
                    onChanged: (value) => setState(() {
                      _local = value;
                      _section = 'overview';
                    }),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.storage),
                    label: Text(
                      _local
                          ? 'Xem lịch sử SQLite'
                          : 'Xem lịch sử đồng bộ Firebase',
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StoredRecordsPage(local: _local),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final (id, label, icon) in [
                          ...sections.where(
                            (item) => ['users', 'lessons'].contains(item.$1),
                          ),
                          ...sections.where(
                            (item) => !['users', 'lessons'].contains(item.$1),
                          ),
                        ])
                          ChoiceChip(
                            avatar: Icon(icon, size: 18),
                            label: Text(label),
                            selected: selected == id,
                            onSelected: (_) => setState(() => _section = id),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _AdminSection(
                      key: ValueKey((
                        selected,
                        isAdmin,
                        _local,
                        gateway.session.user?.uid,
                      )),
                      section: selected,
                      gateway: gateway,
                      isAdmin: isAdmin,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AdminSection extends ConsumerStatefulWidget {
  const _AdminSection({
    super.key,
    required this.section,
    required this.gateway,
    required this.isAdmin,
  });
  final String section;
  final FirebaseAdminGateway gateway;
  final bool isAdmin;

  @override
  ConsumerState<_AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends ConsumerState<_AdminSection> {
  final _search = TextEditingController();
  List<AdminItem> _items = [];
  List<AdminItem> _bundled = [];
  AdminItem _overview = {};
  String? _cursor;
  String? _error;
  String _email = '';
  bool _busy = true;
  String _userFilter = 'all';
  StreamSubscription<List<AdminItem>>? _usersSubscription;
  StreamSubscription<Map<String, List<DateTime>>>? _presenceSubscription;
  Map<String, List<DateTime>> _presence = {};
  Timer? _presenceTimer;
  bool get _content =>
      ['signs', 'categories', 'lessons'].contains(widget.section);

  Future<void> _confirmUserAction(
    AdminItem item, {
    required bool delete,
  }) async {
    final hidden = item['hidden'] == true;
    final label = delete
        ? 'Xóa người dùng'
        : hidden
        ? 'Hiện người dùng'
        : 'Ẩn người dùng';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(
          delete
              ? 'Xóa hồ sơ quản lý và chặn quyền học tập, đồng bộ của người dùng này. Lịch sử được giữ lại. Tài khoản đăng nhập vẫn có trong Firebase Authentication.'
              : hidden
              ? 'Đưa người dùng trở lại danh sách đang hiển thị.'
              : 'Đưa người dùng vào danh sách đã ẩn. Bạn có thể hiện lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _mutate(delete ? 'profileDelete' : 'profileVisibility', {
      'id': item['id'],
      if (!delete) 'hidden': !hidden,
    });
  }

  Future<void> _details(AdminItem item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item['label']?.toString().isNotEmpty == true
              ? item['label'] as String
              : item['email']?.toString() ?? item['id'] as String,
        ),
        scrollable: true,
        content: SelectableText(
          widget.section == 'users'
              ? 'UID: ${item['id']}\nEmail: ${item['email'] ?? ''}\nTên: ${item['label'] ?? ''}\nVai trò: ${AccountRole.parse(item['role']).label}\nTrạng thái: ${item['hidden'] == true ? 'Đã ẩn' : 'Đang hiển thị'}\nQuyền học tập: ${item['locked'] == true ? 'Đã khóa' : 'Đang hoạt động'}'
              : 'Mã bài học: ${item['id']}\nMô tả: ${item['description'] ?? ''}\nSố câu: ${(item['targets'] as List?)?.length ?? 0}\nThứ tự ký hiệu: ${(item['targets'] as List?)?.join(', ') ?? ''}\nTrạng thái: ${item['state'] ?? 'draft'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLesson(AdminItem item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài học?'),
        content: Text(item['label'] as String),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa bài học'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _mutate('delete', {
      'kind': 'lessons',
      'id': item['id'],
      'revision': item['revision'] ?? 0,
      'item': item,
    });
  }

  Future<void> _profile([AdminItem? item]) async {
    final fields = {
      for (final key in ['id', 'email', 'label'])
        key: TextEditingController(text: item?[key] as String?),
    };
    final form = GlobalKey<FormState>();
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Thêm người dùng theo UID' : 'Sửa người dùng',
        ),
        scrollable: true,
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'UID lấy từ Firebase Authentication. Hồ sơ quản lý dữ liệu của người dùng.',
              ),
              for (final key in fields.keys)
                TextFormField(
                  controller: fields[key],
                  readOnly: key == 'id' && item != null,
                  decoration: InputDecoration(
                    labelText: {
                      'id': 'UID',
                      'email': 'Email',
                      'label': 'Tên hiển thị',
                    }[key],
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Hãy nhập giá trị'
                      : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          if (item != null &&
              item['role'] != 'admin' &&
              item['id'] != widget.gateway.session.user?.uid)
            TextButton(
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa người dùng?'),
                    content: const Text(
                      'Xóa hồ sơ quản lý và chặn quyền học tập, đồng bộ. Tài khoản xác thực và lịch sử được giữ lại.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa hồ sơ'),
                      ),
                    ],
                  ),
                );
                if (yes == true && context.mounted) {
                  Navigator.pop(context, 'profileDelete');
                }
              },
              child: const Text('Xóa hồ sơ'),
            ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, 'profileSave');
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final values = {
      for (final entry in fields.entries) entry.key: entry.value.text.trim(),
    };
    for (final field in fields.values) {
      field.dispose();
    }
    if (mounted && action != null) await _mutate(action, values);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(_usersSubscription?.cancel());
    unawaited(_presenceSubscription?.cancel());
    _presenceTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final section = widget.section;
      if (section == 'users') {
        await _usersSubscription?.cancel();
        await _presenceSubscription?.cancel();
        _presenceTimer?.cancel();
        _usersSubscription = widget.gateway.watchUsers().listen(
          (items) {
            if (mounted) {
              setState(() {
                _items = items;
                _busy = false;
                _error = null;
                _cursor = null;
              });
            }
          },
          onError: (Object error) {
            if (mounted) {
              setState(() {
                _error = _message(error);
                _busy = false;
              });
            }
          },
        );
        _presenceSubscription = widget.gateway.watchPresence().listen(
          (presence) {
            if (mounted) setState(() => _presence = presence);
          },
          onError: (Object _) {
            if (mounted) setState(() => _presence = {});
          },
        );
        _presenceTimer = Timer.periodic(const Duration(seconds: 15), (_) {
          if (mounted) setState(() {});
        });
        return;
      }
      final result = await widget.gateway.call(_content ? 'content' : section, {
        if (_content) 'kind': section,
        if (append) 'cursor': _cursor,
        if (section == 'users' && _email.isNotEmpty) 'email': _email,
      });
      final bundled = section == 'signs' && !append
          ? await _bundledSigns()
          : _bundled;
      if (!mounted) return;
      setState(() {
        _overview = result;
        _bundled = bundled;
        _cursor = result['cursor'] as String?;
        _items = [
          if (append) ..._items,
          ...((result['items'] as List?) ?? []).cast<AdminItem>(),
        ];
      });
    } on Exception catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<AdminItem>> _bundledSigns() async {
    final catalog = jsonDecode(
      await rootBundle.loadString('assets/dictionary/catalog.json'),
    ) as AdminItem;
    return [
      for (final item in (catalog['entries'] as List).cast<AdminItem>())
        {
          ...item,
          'id': item['code'],
          'state': 'bundled',
          'licenseName': catalog['licenseName'],
        },
    ];
  }

  Future<void> _edit(AdminItem? item) async {
    final section = widget.section;
    final result = await showDialog<AdminItem>(
      context: context,
      builder: (_) => _ContentEditor(
        section: section,
        item: item,
        isAdmin: widget.isAdmin,
        gateway: widget.gateway,
      ),
    );
    if (result == null || !mounted) return;
    await _mutate(result['action'] as String, {
      'kind': section,
      'id': result['id'],
      'revision': item?['revision'] ?? 0,
      'item': result['item'],
    });
  }

  Future<void> _account(AdminItem item) async {
    final result = await showDialog<AdminItem>(
      context: context,
      builder: (_) => _AccountEditor(item: item),
    );
    if (!mounted || result == null) return;
    await _mutate('account', {'id': item['id'], ...result});
  }

  Future<void> _mutate(String action, AdminItem data) async {
    setState(() => _busy = true);
    try {
      await widget.gateway.call(action, data);
      if (!mounted) return;
      if (_content) {
        if (!widget.gateway.isLocal) {
          ref.invalidate(publishedRefreshProvider(widget.section));
        }
        ref.invalidate(dictionaryProvider);
        ref.invalidate(publishedLessonsProvider);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi.')));
      if (widget.section == 'users') {
        setState(() {
          _items = [
            for (final item in _items)
              if (item['id'] == data['id'])
                {
                  ...item,
                  if (action == 'profileVisibility') 'hidden': data['hidden'],
                  if (action == 'profileDelete') 'deleted': true,
                  if (action == 'profileSave') ...{
                    'email': data['email'],
                    'label': data['label'],
                  },
                  if (action == 'account') ...{
                    'role': data['role'],
                    'locked': data['locked'],
                  },
                }
              else
                item,
          ];
        });
      } else {
        await _load();
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final byId = {
      if (_cursor == null)
        for (final item in _bundled) item['id']: item,
      for (final item in _items)
        item['id']: {
          ...?_bundled
              .where((bundled) => bundled['id'] == item['id'])
              .firstOrNull,
          ...item,
        },
    };
    final rows = byId.values
        .where(
          (item) =>
              section != 'users' ||
              (item['deleted'] != true &&
                  (_userFilter == 'all' ||
                      (item['hidden'] == true) == (_userFilter == 'hidden')) &&
                  (item['email']?.toString().toLowerCase().contains(
                        _email.toLowerCase(),
                      ) ??
                      _email.isEmpty)),
        )
        .toList();
    final title = section == 'users'
        ? 'Người dùng (${rows.length})'
        : _sections.firstWhere((entry) => entry.$1 == section).$2;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _busy ? null : () => _load(),
              icon: const Icon(Icons.refresh),
            ),
            if (_content)
              TextButton.icon(
                label: Text(section == 'lessons' ? 'Thêm bài học' : 'Thêm mới'),
                onPressed: _busy ? null : () => _edit(null),
                icon: const Icon(Icons.add),
              ),
            if (section == 'users')
              IconButton(
                tooltip: 'Thêm người dùng theo UID',
                onPressed: _busy ? null : () => _profile(),
                icon: const Icon(Icons.person_add_outlined),
              ),
          ],
        ),
        if (section == 'users')
          Wrap(
            spacing: 8,
            children: [
              for (final (value, label) in [
                ('visible', 'Đang hiển thị'),
                ('hidden', 'Đã ẩn'),
                ('all', 'Tất cả'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _userFilter == value,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _userFilter = value),
                ),
            ],
          ),
        if (section == 'users')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _search,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Tìm theo email',
                suffixIcon: IconButton(
                  tooltip: 'Tìm',
                  icon: const Icon(Icons.search),
                  onPressed: _busy
                      ? null
                      : () {
                          _email = _search.text.trim();
                          setState(() {});
                        },
                ),
              ),
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        if (_error case final String message)
          EmptyPanel(icon: Icons.error_outline, message: message),
        if (!_busy && _error == null && rows.isEmpty && section != 'overview')
          const EmptyPanel(
            icon: Icons.inbox_outlined,
            message: 'Chưa có dữ liệu.',
          ),
        if (section == 'overview' && _overview.isNotEmpty)
          for (final (key, label, icon) in [
            (
              'signs',
              'Ký hiệu xuất bản qua quản trị',
              Icons.sign_language_outlined,
            ),
            ('categories', 'Danh mục đã xuất bản', Icons.category_outlined),
            ('lessons', 'Bộ bài đã xuất bản', Icons.school_outlined),
            ('pending', 'Nội dung nháp', Icons.edit_note),
            if (widget.gateway.isLocal)
              ('history', 'Lịch sử SQLite', Icons.history),
            if (widget.gateway.isLocal)
              ('sessions', 'Phiên luyện tập SQLite', Icons.school),
            if (!widget.gateway.isLocal)
              ('users', 'Hồ sơ người dùng Firebase', Icons.people),
          ])
            Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: Text('${_overview[key] ?? 0}'),
              ),
            ),
        for (final item in rows) Card(child: _tile(item)),
        if (_cursor != null)
          OutlinedButton(
            onPressed: _busy ? null : () => _load(append: true),
            child: const Text('Tải thêm'),
          ),
      ],
    );
  }

  Widget _tile(AdminItem item) {
    if (widget.section == 'users') {
      final role = AccountRole.parse(item['role']);
      final locked = item['locked'] == true;
      final online = isUserOnline(
        _presence[item['id']] ?? const [],
        DateTime.now(),
      );
      final protected =
          item['id'] == widget.gateway.session.user?.uid ||
          role == AccountRole.admin;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(
                Icons.circle,
                size: 12,
                color: online
                    ? Colors.green
                    : Theme.of(context).colorScheme.outline,
              ),
              contentPadding: EdgeInsets.zero,
              title: Text(
                item['email']?.toString().isNotEmpty == true
                    ? item['email'] as String
                    : item['id'] as String,
              ),
              subtitle: Text(
                '${online ? 'Online' : 'Offline'} · ${role.label}\n${item['hidden'] == true ? 'Đã ẩn' : 'Đang hiển thị'} · ${locked ? 'Đã khóa' : 'Đang hoạt động'}',
              ),
              onTap: _busy ? null : () => _details(item),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _details(item),
                  child: const Text('Xem'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _profile(item),
                  child: const Text('Sửa hồ sơ'),
                ),
                if (!protected) ...[
                  TextButton(
                    onPressed: _busy ? null : () => _account(item),
                    child: const Text('Phân quyền'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _confirmUserAction(item, delete: false),
                    child: Text(item['hidden'] == true ? 'Hiện lại' : 'Ẩn'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _confirmUserAction(item, delete: true),
                    child: const Text('Xóa'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
    if (widget.section == 'audit') {
      final action = switch (item['action']) {
        'save' => 'Lưu nháp',
        'publish' => 'Xuất bản',
        'hide' => 'Ẩn nội dung',
        'account' => 'Cập nhật tài khoản',
        _ => 'Cập nhật',
      };
      final date = DateTime.tryParse(item['at']?.toString() ?? '')?.toLocal();
      final localizations = MaterialLocalizations.of(context);
      final time = date == null
          ? ''
          : '${localizations.formatCompactDate(date)} '
                '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
      return ListTile(
        title: Text('$action · ${item['label'] ?? item['target']}'),
        subtitle: Text('$time · ${item['actor']}'),
      );
    }
    final status = switch (item['state']) {
      'published' => 'Đã xuất bản',
      'hidden' => 'Đã ẩn',
      'bundled' => 'Có sẵn trong ứng dụng',
      _ => 'Bản nháp',
    };
    if (widget.section == 'lessons') {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['label'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${(item['targets'] as List?)?.length ?? 0} câu · $status'),
            if ((item['description'] as String?)?.isNotEmpty == true)
              Text(
                item['description'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : () => _details(item),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Xem'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _edit(item),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa'),
                ),
                if (widget.isAdmin)
                  TextButton.icon(
                    onPressed: _busy ? null : () => _deleteLesson(item),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return ListTile(
      title: Text(item['label'] as String),
      subtitle: Text('${item['id']} · $status'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _busy ? null : () => _edit(item),
    );
  }
}

class _ContentEditor extends ConsumerStatefulWidget {
  const _ContentEditor({
    required this.section,
    required this.item,
    required this.isAdmin,
    required this.gateway,
  });
  final String section;
  final AdminItem? item;
  final bool isAdmin;
  final FirebaseAdminGateway gateway;

  @override
  ConsumerState<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends ConsumerState<_ContentEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late final Future<List<AdminItem>> _categories;
  String? _category;
  bool get _sign => widget.section == 'signs';
  bool get _lesson => widget.section == 'lessons';

  @override
  void initState() {
    super.initState();
    _category = widget.item?['categoryId'] as String?;
    _categories = _sign && widget.gateway.isLocal
        ? ref.read(publishedContentProvider).read('categories')
        : _sign
        ? fetchPublished(widget.gateway.session.firestore, 'categories').then(
            (items) =>
                items.where((item) => item['state'] == 'published').toList(),
          )
        : Future.value([]);
  }

  TextEditingController _controller(String key) => _fields.putIfAbsent(key, () {
    final value = widget.item?[key];
    return TextEditingController(
      text: value is List ? value.join(', ') : value?.toString(),
    );
  });

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controller(key),
      readOnly: key == 'id' && widget.item != null,
      decoration: InputDecoration(labelText: label),
      maxLines: lines,
      validator: (text) {
        if (required && (text?.trim().isEmpty ?? true)) {
          return 'Hãy nhập $label';
        }
        if (key == 'id' &&
            !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(text!.trim())) {
          return 'Chỉ dùng chữ không dấu, số, dấu gạch ngang hoặc gạch dưới';
        }
        return null;
      },
    ),
  );

  void _finish(String action) {
    final id = _controller('id').text.trim();
    if (action == 'hide' || action == 'delete') {
      Navigator.pop(context, {
        'action': action,
        'id': id,
        'item': {'label': widget.item!['label']},
      });
      return;
    }
    if (!_form.currentState!.validate()) return;
    final data = {
      for (final entry in _fields.entries)
        if (entry.key != 'id') entry.key: entry.value.text.trim(),
    };
    final targets = _lesson
        ? data
              .remove('targets')!
              .toUpperCase()
              .split(RegExp(r'[\s,]+'))
              .where((s) => s.isNotEmpty)
              .toList()
        : null;
    final supported = ref.read(supportedPracticeLabelsProvider).asData?.value;
    if ((targets != null &&
            (targets.isEmpty ||
                targets.length > 30 ||
                supported == null ||
                !targets.every(supported.contains))) ||
        (_sign &&
            data['modelLabel']!.isNotEmpty &&
            (supported == null || !supported.contains(data['modelLabel'])))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn tối đa 30 câu và dùng nhãn mà mô hình hỗ trợ.'),
        ),
      );
      return;
    }
    Navigator.pop(context, {
      'action': action,
      'id': id,
      'item': {
        ...data,
        if (_sign) 'categoryId': _category ?? '',
        'targets': ?targets,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_lesson || _sign) ref.watch(supportedPracticeLabelsProvider);
    return AlertDialog(
      title: Text(widget.item == null ? 'Thêm nội dung' : 'Chỉnh sửa nội dung'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('id', 'Mã', required: true),
            _field('label', 'Tên', required: true),
            if (_sign || _lesson) _field('description', 'Mô tả', lines: 2),
            if (_lesson) ...[
              _field(
                'targets',
                'Nhãn theo thứ tự, ví dụ A, B, A',
                required: true,
              ),
              TextButton(
                onPressed: () {
                  final targets = _controller('targets').text
                      .trim()
                      .toUpperCase()
                      .split(RegExp(r'[\s,]+'))
                      .where((s) => s.isNotEmpty)
                      .toList();
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Xem trước · ${targets.length} câu'),
                      scrollable: true,
                      content: Text(
                        targets.indexed
                            .map((entry) => '${entry.$1 + 1}. ${entry.$2}')
                            .join('\n'),
                      ),
                    ),
                  );
                },
                child: const Text('Xem trước thứ tự câu hỏi'),
              ),
            ],
            if (_sign) ...[
              FutureBuilder(
                future: _categories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('Không tải được danh mục đã xuất bản.');
                  }
                  final categories = snapshot.data!;
                  final value = _category ?? '';
                  return DropdownButtonFormField<String>(
                    initialValue: value,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục đã xuất bản',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Dùng tên nhóm bên dưới'),
                      ),
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category['id'] as String,
                          child: Text(category['label'] as String),
                        ),
                      if (value.isNotEmpty &&
                          !categories.any((item) => item['id'] == value))
                        DropdownMenuItem(
                          value: value,
                          child: Text('Danh mục đã ẩn ($value)'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                  );
                },
              ),
              _field('category', 'Tên nhóm mặc định'),
              _field('signSystem', 'Hệ ký hiệu', required: true),
              _field('instructions', 'Hướng dẫn', lines: 2),
              _field('modelLabel', 'Nhãn mô hình (tùy chọn)'),
              _field('imageAsset', 'Đường dẫn ảnh có sẵn trong ứng dụng'),
              _field('videoAsset', 'Đường dẫn video có sẵn trong ứng dụng'),
              _field('sourceUrl', 'Liên kết nguồn HTTPS', required: true),
              _field('licenseName', 'Giấy phép', required: true),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.isAdmin && widget.item != null)
          TextButton(
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa nội dung này?'),
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
              if (yes == true && mounted) _finish('delete');
            },
            child: const Text('Xóa'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        if (widget.isAdmin &&
            widget.item != null &&
            widget.item!['state'] != 'hidden')
          TextButton(
            onPressed: () async {
              final hide = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ẩn nội dung này?'),
                  content: const Text(
                    'Người học sẽ thấy thay đổi khi tải nội dung lần tiếp theo.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ẩn'),
                    ),
                  ],
                ),
              );
              if (hide == true && mounted) _finish('hide');
            },
            child: const Text('Ẩn'),
          ),
        OutlinedButton(
          onPressed: () => _finish('save'),
          child: const Text('Lưu nháp'),
        ),
        if (widget.isAdmin)
          FilledButton(
            onPressed: () => _finish('publish'),
            child: const Text('Xuất bản'),
          ),
      ],
    );
  }
}

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({required this.item});
  final AdminItem item;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  late AccountRole _role = AccountRole.parse(widget.item['role']);
  late bool _locked = widget.item['locked'] == true;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Quyền và trạng thái tài khoản'),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          (widget.item['email'] as String?)?.isNotEmpty == true
              ? widget.item['email'] as String
              : widget.item['id'] as String,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AccountRole>(
          initialValue: _role,
          decoration: const InputDecoration(labelText: 'Vai trò'),
          items: [
            for (final role in AccountRole.values)
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: (role) => setState(() {
            _role = role!;
            if (_role == AccountRole.admin) _locked = false;
          }),
        ),
        SwitchListTile(
          title: const Text('Khóa quyền sử dụng tài khoản'),
          value: _locked,
          onChanged: _role == AccountRole.admin
              ? null
              : (locked) => setState(() => _locked = locked),
        ),
        if (_role == AccountRole.admin)
          const Text(
            'Vai trò quản trị viên chỉ có thể được thu hồi từ Firebase Console.',
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          'role': _role.name,
          'locked': _locked,
          'previousRole': widget.item['role'],
          'previousLocked': widget.item['locked'],
        }),
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
