import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseSessionProvider = Provider<FirebaseSession?>((ref) => null);

class FirebaseSession {
  const FirebaseSession(this.auth, this.firestore, this.user);
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final User? user;
}

Future<FirebaseApp?> initializeFirebase() async {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  if (apiKey.isEmpty &&
      appId.isEmpty &&
      projectId.isEmpty &&
      senderId.isEmpty) {
    return null;
  }
  if ([apiKey, appId, projectId, senderId].any((value) => value.isEmpty)) {
    throw StateError('Firebase configuration is incomplete');
  }
  return Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: senderId,
    ),
  );
}
