import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/firebase_session.dart';

class PresenceTracker {
  PresenceTracker(this.session);
  final FirebaseSession session;
  Future<void> _tail = Future.value();
  String? _device;
  bool _disposed = false;
  bool _online = false;
  Timer? _timer;

  Future<String> _deviceId() async {
    if (_device != null) return _device!;
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/presence-device-id');
    if (await file.exists()) {
      return _device = (await file.readAsString()).trim();
    }
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await file.writeAsString(id, flush: true);
    return _device = id;
  }

  void setForeground(bool value) {
    if (_disposed || session.user == null || value == _online) return;
    _online = value;
    _timer?.cancel();
    _enqueue(value);
    if (value) {
      _timer = Timer.periodic(
        const Duration(seconds: 45),
        (_) => _enqueue(true),
      );
    }
  }

  void _enqueue(bool online) {
    final uid = session.user?.uid;
    if (uid == null) return;
    _tail = _tail.then((_) async {
      try {
        final device = await _deviceId();
        await session.firestore
            .collection('userPresence')
            .doc('${uid}_$device')
            .set({
              'uid': uid,
              'online': online,
              'lastSeen': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 5));
      } on Exception {
        // Missing acknowledgements expire automatically in the admin view.
      }
    });
  }

  Future<void> goOffline() {
    setForeground(false);
    return _tail;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    if (_online) _enqueue(false);
    _online = false;
  }
}
