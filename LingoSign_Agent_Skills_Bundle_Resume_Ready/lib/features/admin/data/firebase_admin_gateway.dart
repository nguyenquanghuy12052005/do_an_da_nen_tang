import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/firebase_session.dart';
import '../../../data/local/app_database.dart';

typedef AdminItem = Map<String, dynamic>;

class AdminFailure implements Exception {
  const AdminFailure(this.status);
  final String status;
  String get message => switch (status) {
    'permission-denied' => 'Không đủ quyền. Hãy kiểm tra Firestore rules.',
    'aborted' => 'Dữ liệu đã thay đổi. Hãy tải lại trước khi lưu.',
    'invalid-argument' => 'Dữ liệu chưa hợp lệ. Hãy kiểm tra các trường.',
    _ => 'Không tải được dữ liệu. Kiểm tra mạng rồi thử lại.',
  };
}

class FirebaseAdminGateway {
  const FirebaseAdminGateway(this.session, {this.database});
  final FirebaseSession session;
  final AppDatabase? database;
  bool get isLocal => database != null;
  FirebaseFirestore get db => session.firestore;
  static const kinds = ['signs', 'categories', 'lessons'];

  Stream<List<AdminItem>> watchUsers() {
    late StreamController<List<AdminItem>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    profilesSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    policiesSubscription;
    QuerySnapshot<Map<String, dynamic>>? profiles;
    QuerySnapshot<Map<String, dynamic>>? policies;
    void emit() {
      if (profiles == null || policies == null || controller.isClosed) return;
      final byId = {for (final doc in policies!.docs) doc.id: doc.data()};
      final items =
          [
            for (final doc in profiles!.docs)
              <String, dynamic>{
                ...doc.data(),
                'id': doc.id,
                'role': byId[doc.id]?['role'] ?? 'learner',
                'locked': byId[doc.id]?['locked'] ?? false,
                'disabled': doc.data()['authDisabled'] == true,
              },
          ]..sort(
            (a, b) => (a['email'] as String? ?? '').compareTo(
              b['email'] as String? ?? '',
            ),
          );
      controller.add(items);
    }

    controller = StreamController<List<AdminItem>>(
      onListen: () {
        profilesSubscription = db.collection('users').snapshots().listen((
          value,
        ) {
          profiles = value;
          emit();
        }, onError: controller.addError);
        policiesSubscription = db
            .collection('accountAccess')
            .snapshots()
            .listen((value) {
              policies = value;
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await profilesSubscription?.cancel();
        await policiesSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<Map<String, List<DateTime>>> watchPresence() => db
      .collection('userPresence')
      .where('online', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final byUser = <String, List<DateTime>>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['uid'] is! String ||
              data['lastSeen'] is! Timestamp ||
              doc.metadata.hasPendingWrites) {
            continue;
          }
          byUser
              .putIfAbsent(data['uid'] as String, () => [])
              .add((data['lastSeen'] as Timestamp).toDate());
        }
        return byUser;
      });

  Future<AdminItem> call(String action, [AdminItem data = const {}]) async {
    try {
      if (isLocal) return await _local(action, data);
      final uid = session.user?.uid;
      if (uid == null) throw const AdminFailure('permission-denied');
      if (action == 'profileSave' ||
          action == 'profileDelete' ||
          action == 'profileVisibility') {
        final target = db.collection('users').doc(data['id'] as String);
        final policyRef = db.collection('accountAccess').doc(target.id);
        await db.runTransaction((tx) async {
          final before = await tx.get(target);
          final policy = (await tx.get(policyRef)).data() ?? {};
          if (action != 'profileSave' &&
              (target.id == uid || policy['role'] == 'admin')) {
            throw const AdminFailure('permission-denied');
          }
          if (action == 'profileSave') {
            if (before.data()?['deleted'] == true) {
              throw const AdminFailure('aborted');
            }
            tx.set(target, {
              'email': data['email'],
              'label': data['label'],
            }, SetOptions(merge: true));
          } else if (action == 'profileVisibility') {
            if (!before.exists || before.data()?['deleted'] == true) {
              throw const AdminFailure('aborted');
            }
            tx.update(target, {'hidden': data['hidden']});
          } else {
            tx.set(target, {
              'deleted': true,
              'hidden': true,
              'deletedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            tx.set(policyRef, {
              'role': policy['role'] ?? 'learner',
              'locked': true,
            });
          }
          tx.set(db.collection('adminAudit').doc(), {
            'actor': uid,
            'action': action,
            'target': target.id,
            'at': FieldValue.serverTimestamp(),
          });
        });
        return {};
      }
      if (action == 'overview') {
        final result = <String, dynamic>{};
        for (final kind in kinds) {
          result[kind] =
              (await db
                      .collection('published_$kind')
                      .where('state', isEqualTo: 'published')
                      .count()
                      .get())
                  .count;
        }
        final policy = await db.collection('accountAccess').doc(uid).get();
        if (policy.data()?['role'] == 'admin') {
          final total = (await db.collection('users').count().get()).count ?? 0;
          final deleted =
              (await db
                      .collection('users')
                      .where('deleted', isEqualTo: true)
                      .count()
                      .get())
                  .count ??
              0;
          result['users'] = total - deleted;
        }
        result['pending'] = 0;
        for (final kind in kinds) {
          result['pending'] +=
              (await db
                      .collection('admin_$kind')
                      .where('state', isEqualTo: 'draft')
                      .count()
                      .get())
                  .count ??
              0;
        }
        return result;
      }
      if (action == 'users' || action == 'content' || action == 'audit') {
        final collection = action == 'users'
            ? 'users'
            : action == 'audit'
            ? 'adminAudit'
            : 'admin_${data['kind']}';
        if (action == 'content' && !kinds.contains(data['kind'])) {
          throw const AdminFailure('invalid-argument');
        }
        Query<Map<String, dynamic>> query = db.collection(collection);
        if (action == 'users' && data['email'] != null) {
          query = query.where('email', isEqualTo: data['email']);
        }
        query = action == 'audit'
            ? query.orderBy('at', descending: true)
            : query.orderBy(FieldPath.documentId);
        if (data['cursor'] case final String cursor) {
          final after = await db.collection(collection).doc(cursor).get();
          if (after.exists) query = query.startAfterDocument(after);
        }
        final page = await query
            .limit(30)
            .get(const GetOptions(source: Source.server));
        final items = <AdminItem>[];
        for (final doc in page.docs) {
          final item = {...doc.data(), 'id': doc.id};
          if (action == 'users') {
            final policy =
                (await db.collection('accountAccess').doc(doc.id).get()).data();
            item.addAll({
              'role': policy?['role'] ?? 'learner',
              'locked': policy?['locked'] ?? false,
              'disabled': false,
            });
          }
          if (item['at'] case final Timestamp at) {
            item['at'] = at.toDate().toIso8601String();
          }
          items.add(item);
        }
        return {
          'items': items,
          'cursor': page.size == 30 ? page.docs.last.id : null,
        };
      }
      if (action == 'account') {
        final target = db.collection('accountAccess').doc(data['id'] as String);
        await db.runTransaction((tx) async {
          final before = (await tx.get(target)).data() ?? {};
          if ((before['role'] ?? 'learner') != data['previousRole'] ||
              (before['locked'] ?? false) != data['previousLocked']) {
            throw const AdminFailure('aborted');
          }
          tx.set(target, {'role': data['role'], 'locked': data['locked']});
          tx.set(db.collection('adminAudit').doc(), {
            'actor': uid,
            'action': action,
            'target': data['id'],
            'at': FieldValue.serverTimestamp(),
          });
        });
        return {};
      }
      final kind = data['kind'];
      if (!kinds.contains(kind)) throw const AdminFailure('invalid-argument');
      final ref = db.collection('admin_$kind').doc(data['id'] as String);
      final publicRef = db.collection('published_$kind').doc(ref.id);
      await db.runTransaction((tx) async {
        final before = (await tx.get(ref)).data();
        if ((before?['revision'] ?? 0) != data['revision']) {
          throw const AdminFailure('aborted');
        }
        final state = action == 'publish'
            ? 'published'
            : ['hide', 'delete'].contains(action)
            ? 'hidden'
            : 'draft';
        final next = <String, dynamic>{
          ...?(action == 'hide' || action == 'delete'
              ? before
              : data['item'] as AdminItem?),
          'label':
              (data['item'] as Map?)?['label'] ?? before?['label'] ?? ref.id,
          'state': state,
          'revision': (data['revision'] as int) + 1,
        };
        if (action == 'delete') {
          tx.delete(ref);
        } else {
          tx.set(ref, next);
        }
        if (action == 'publish') tx.set(publicRef, next);
        if (action == 'hide' || action == 'delete') {
          tx.set(publicRef, {'state': 'hidden'});
        }
        tx.set(db.collection('adminAudit').doc(), {
          'actor': uid,
          'action': action,
          'kind': kind,
          'target': ref.id,
          'label': next['label'],
          'at': FieldValue.serverTimestamp(),
        });
      });
      return {};
    } on FirebaseException catch (error) {
      throw AdminFailure(error.code);
    }
  }

  Future<List<AdminItem>> _read(String key) async {
    final row = await (database!.select(
      database!.appSettings,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row == null
        ? []
        : (jsonDecode(row.valueJson) as List).cast<AdminItem>();
  }

  Future<void> _write(String key, List<AdminItem> items) => database!
      .into(database!.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          valueJson: jsonEncode(items),
          updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<AdminItem> _local(String action, AdminItem data) async {
    if (action == 'overview') {
      return {
        for (final kind in kinds)
          kind: (await _read('local_published_$kind'))
              .where((item) => item['state'] == 'published')
              .length,
        'history':
            (await database!.select(database!.recognitionHistoryRows).get())
                .length,
        'sessions':
            (await database!.select(database!.learningSessions).get()).length,
      };
    }
    if (action == 'audit') {
      return {'items': (await _read('local_admin_audit')).reversed.toList()};
    }
    final kind = data['kind'];
    if (!kinds.contains(kind)) throw const AdminFailure('invalid-argument');
    if (action == 'content') return {'items': await _read('local_admin_$kind')};
    await database!.transaction(() async {
      final items = await _read('local_admin_$kind');
      final index = items.indexWhere((item) => item['id'] == data['id']);
      final before = index < 0 ? null : items[index];
      if ((before?['revision'] ?? 0) != data['revision']) {
        throw const AdminFailure('aborted');
      }
      final state = action == 'publish'
          ? 'published'
          : ['hide', 'delete'].contains(action)
          ? 'hidden'
          : 'draft';
      final next = <String, dynamic>{
        ...?(action == 'hide' || action == 'delete'
            ? before
            : data['item'] as AdminItem?),
        'id': data['id'],
        'label':
            (data['item'] as Map?)?['label'] ?? before?['label'] ?? data['id'],
        'state': state,
        'revision': (data['revision'] as int) + 1,
      };
      if (index >= 0) items.removeAt(index);
      if (action != 'delete') items.add(next);
      await _write('local_admin_$kind', items);
      if (action != 'save') {
        final published = await _read('local_published_$kind');
        published.removeWhere((item) => item['id'] == data['id']);
        published.add(next);
        await _write('local_published_$kind', published);
      }
      final audit = await _read('local_admin_audit');
      audit.add({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'actor': session.user!.uid,
        'action': action,
        'target': data['id'],
        'label': next['label'],
        'at': DateTime.now().toIso8601String(),
      });
      await _write('local_admin_audit', audit);
    });
    return {};
  }
}
