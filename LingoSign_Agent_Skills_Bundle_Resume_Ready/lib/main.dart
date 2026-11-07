import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/app.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/app/firebase_session.dart';
import 'package:lingosign_ai/features/recognition/data/camera/camera_plugin_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var phase = 'Firebase Core';
  try {
    final firebase = await initializeFirebase();
    if (firebase == null) {
      runApp(const _SessionApp());
      return;
    }
    phase = 'Firebase Auth';
    final auth = FirebaseAuth.instanceFor(app: firebase);
    phase = 'Firestore';
    final firestore = FirebaseFirestore.instanceFor(app: firebase);
    // Drift is the durable local store. Firestore ACKs must come from the server.
    firestore.settings = const Settings(persistenceEnabled: false);
    final changes = auth.authStateChanges();
    runApp(
      StreamBuilder<User?>(
        stream: changes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text(
                    'Không đọc được phiên tài khoản. Hãy mở lại ứng dụng.',
                  ),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          return _SessionApp(
            key: ValueKey(snapshot.data?.uid),
            session: FirebaseSession(auth, firestore, snapshot.data),
          );
        },
      ),
    );
  } catch (error) {
    debugPrint(
      'LingoSign startup: ' + phase + ' ' + error.runtimeType.toString(),
    );
    if (error is FirebaseException) debugPrint('Firebase code: ' + error.code);
    if (error is PlatformException) debugPrint('Platform code: ' + error.code);
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Không khởi tạo được Firebase. Hãy kiểm tra cấu hình.'),
          ),
        ),
      ),
    );
  }
}

class _SessionApp extends StatefulWidget {
  const _SessionApp({super.key, this.session});
  final FirebaseSession? session;

  @override
  State<_SessionApp> createState() => _SessionAppState();
}

class _SessionAppState extends State<_SessionApp> {
  final _camera = CameraPluginGateway();

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      cameraGatewayProvider.overrideWithValue(_camera),
      firebaseSessionProvider.overrideWithValue(widget.session),
    ],
    child: const LingoSignApp(),
  );
}
