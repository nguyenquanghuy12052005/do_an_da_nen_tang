import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/firebase_session.dart';

class AccountSettings extends ConsumerWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(firebaseSessionProvider);
    if (session == null) return const SizedBox.shrink();
    final user = session.user;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(user?.email ?? 'Tài khoản học tập'),
        subtitle: Text(
          user == null
              ? 'Đăng nhập để lưu lịch sử và tiến độ theo tài khoản.'
              : 'Lịch sử và tiến độ lưu riêng cho tài khoản này.',
        ),
        trailing: TextButton(
          onPressed: user == null
              ? () => showDialog<void>(
                  context: context,
                  builder: (_) => _CredentialsDialog(auth: session.auth),
                )
              : () async {
                  try {
                    await session.auth.signOut();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không đăng xuất được. Hãy thử lại.'),
                        ),
                      );
                    }
                  }
                },
          child: Text(user == null ? 'Đăng nhập' : 'Đăng xuất'),
        ),
      ),
    );
  }
}

class _CredentialsDialog extends StatefulWidget {
  const _CredentialsDialog({required this.auth});
  final FirebaseAuth auth;

  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Nhập email và mật khẩu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await widget.auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.code) {
          'invalid-email' => 'Email không hợp lệ.',
          'weak-password' => 'Mật khẩu chưa đủ mạnh.',
          'email-already-in-use' => 'Email này đã được đăng ký.',
          'network-request-failed' =>
            'Cần kết nối mạng để đăng nhập hoặc đăng ký.',
          'too-many-requests' => 'Bạn đã thử nhiều lần. Hãy thử lại sau.',
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' => 'Email hoặc mật khẩu không đúng.',
          _ => 'Không xác thực được tài khoản. Hãy thử lại.',
        },
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Không xác thực được tài khoản.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(_register ? 'Tạo tài khoản' : 'Đăng nhập'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _register = !_register;
                  _error = null;
                }),
          child: Text(_register ? 'Đã có tài khoản' : 'Tạo tài khoản'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(
            _busy ? 'Đang xử lý…' : (_register ? 'Đăng ký' : 'Đăng nhập'),
          ),
        ),
      ],
    ),
  );
}
