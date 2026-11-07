import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_components.dart';
import '../../../app/firebase_session.dart';
import 'auth_page.dart';

class AccountSettings extends ConsumerWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(firebaseSessionProvider);
    if (session == null) return const SizedBox.shrink();
    final user = session.user;
    return Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            leading: AccentIcon(
              Icons.person_outline,
              accent: AppAccents.colors[3],
            ),
            title: Text(user?.email ?? 'Tài khoản học tập'),
            subtitle: Text(user == null ? 'Chưa đăng nhập' : 'Đã đăng nhập'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: user == null
                    ? () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AuthPage(auth: session.auth),
                        ),
                      )
                    : () async {
                        try {
                          await session.auth.signOut();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không đăng xuất được. Hãy thử lại.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Text(user == null ? 'Đăng nhập' : 'Đăng xuất'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
