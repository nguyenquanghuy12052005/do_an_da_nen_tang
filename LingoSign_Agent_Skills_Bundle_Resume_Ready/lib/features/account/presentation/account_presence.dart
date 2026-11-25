import 'package:flutter/widgets.dart';

import '../../../app/firebase_session.dart';
import '../data/presence_tracker.dart';

class AccountPresence extends StatefulWidget {
  const AccountPresence({
    super.key,
    required this.session,
    required this.child,
  });
  final FirebaseSession session;
  final Widget child;
  static Future<void> markOffline(BuildContext context) async {
    await context
        .findAncestorStateOfType<_AccountPresenceState>()
        ?._tracker
        .goOffline();
  }

  @override
  State<AccountPresence> createState() => _AccountPresenceState();
}

class _AccountPresenceState extends State<AccountPresence>
    with WidgetsBindingObserver {
  late final PresenceTracker _tracker;

  @override
  void initState() {
    super.initState();
    _tracker = PresenceTracker(widget.session);
    WidgetsBinding.instance.addObserver(this);
    _tracker.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _tracker.setForeground(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
