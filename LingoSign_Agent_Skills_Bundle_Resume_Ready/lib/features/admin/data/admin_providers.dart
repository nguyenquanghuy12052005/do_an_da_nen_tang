import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/firebase_session.dart';
import '../domain/account_access.dart';
import 'firebase_admin_gateway.dart';

final accountAccessProvider = StreamProvider.autoDispose<AccountAccess>((ref) {
  final session = ref.watch(firebaseSessionProvider);
  final user = session?.user;
  if (session == null || user == null) {
    return Stream.value(const AccountAccess());
  }
  Future<void>(() async {
    try {
      final profile = session.firestore.collection('users').doc(user.uid);
      await session.firestore.runTransaction((transaction) async {
        if (!(await transaction.get(profile)).exists) {
          transaction.set(profile, {
            'email': user.email ?? '',
            'label': user.displayName ?? '',
          });
        }
      });
    } on FirebaseException {
      // Profile registration can retry the next time the session is opened.
    }
  });
  return session.firestore
      .collection('accountAccess')
      .doc(user.uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        final data = snapshot.data();
        return AccountAccess(
          role: snapshot.metadata.isFromCache
              ? AccountRole.learner
              : AccountRole.parse(data?['role']),
          locked: data?['locked'] == true,
        );
      });
});

final adminGatewayProvider = Provider.autoDispose<FirebaseAdminGateway?>((ref) {
  final session = ref.watch(firebaseSessionProvider);
  return session?.user == null ? null : FirebaseAdminGateway(session!);
});

Future<List<AdminItem>> fetchPublished(
  FirebaseFirestore firestore,
  String kind,
) async {
  final snapshot = await firestore
      .collection('published_$kind')
      .get(const GetOptions(source: Source.server))
      .timeout(const Duration(seconds: 4));
  return [
    for (final doc in snapshot.docs) {...doc.data(), 'id': doc.id},
  ];
}
