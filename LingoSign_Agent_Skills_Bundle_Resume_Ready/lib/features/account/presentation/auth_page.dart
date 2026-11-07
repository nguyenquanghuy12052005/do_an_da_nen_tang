import '../../../app/silent_moon_art.dart';
import '../../../app/theme/app_theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.auth});

  final FirebaseAuth auth;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _switchMode() {
    FocusScope.of(context).unfocus();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _register = !_register;
      _showPassword = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;
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
      if (mounted) {
        TextInput.finishAutofillContext();
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.code) {
          'invalid-email' => 'Email không hợp lệ.',
          'weak-password' => 'Mật khẩu chưa đủ mạnh.',
          'email-already-in-use' => 'Email này đã được đăng ký.',
          'network-request-failed' => 'Kiểm tra kết nối mạng rồi thử lại.',
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.brightness == Brightness.dark
                          ? [AppTheme.midnight, colors.primaryContainer]
                          : const [Color(0xFF514AA9), Color(0xFF675EBC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: IconButton(
                            tooltip: 'Quay lại',
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            color: Colors.white,
                            disabledColor: Colors.white54,
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(height: 96, child: SilentMoonArt()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LingoSign',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildForm(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    _register ? 'Tạo tài khoản' : 'Đăng nhập',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _register
                      ? 'Bắt đầu luyện ký hiệu.'
                      : 'Tiếp tục luyện ký hiệu.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Nhập email.';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(email)) {
                      return 'Email không hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: !_showPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: _register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: _register ? null : (_) => _submit(),
                  autofillHints: [
                    _register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                      onPressed: _busy
                          ? null
                          : () =>
                                setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nhập mật khẩu.';
                    }
                    if (_register && value.length < 6) {
                      return 'Dùng ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                ),
                if (_register) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmation,
                    enabled: !_busy,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập lại mật khẩu.';
                      }
                      if (value != _password.text) {
                        return 'Mật khẩu không khớp.';
                      }
                      return null;
                    },
                  ),
                ],
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(error, style: TextStyle(color: colors.error)),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Đang xử lý',
                          ),
                        )
                      : Text(_register ? 'Đăng ký' : 'Đăng nhập'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _switchMode,
                  child: Text(
                    _register
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
