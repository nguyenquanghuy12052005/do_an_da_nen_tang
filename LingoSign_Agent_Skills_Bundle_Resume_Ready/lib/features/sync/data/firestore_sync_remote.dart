import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../learning/domain/practice_session.dart';
import '../domain/entities/sync_operation.dart';
import '../domain/repositories/sync_remote.dart';

class FirestoreSyncRemote implements SyncRemote {
  FirestoreSyncRemote(this.firestore, String uid)
    : events = firestore.collection('users').doc(uid).collection('syncEvents');

  final FirebaseFirestore firestore;
  final CollectionReference<Map<String, dynamic>> events;
  static const _timeout = Duration(seconds: 10);

  @override
  Future<void> push(SyncOperation operation) {
    final console = _consoleFields(operation);
    final event = events.doc('${console.title} - ${operation.id}');
    final legacyEvent = events.doc(operation.id);
    final payload = jsonEncode(operation.record);
    return firestore
        .runTransaction<void>((transaction) async {
          var existing = await transaction.get(event);
          if (!existing.exists) {
            existing = await transaction.get(legacyEvent);
          }
          if (existing.exists) {
            if (existing.data()?['payload'] != payload) {
              throw StateError(
                'Sync operation ID already has a different payload',
              );
            }
            return;
          }
          transaction.set(event, {
            'payload': payload,
            ...console.fields,
            'committedAt': FieldValue.serverTimestamp(),
          });
        })
        .timeout(_timeout);
  }

  // Keep the original payload format for devices running an older build.
  ({String title, Map<String, Object?> fields}) _consoleFields(
    SyncOperation operation,
  ) {
    final record = operation.record;
    if (record['learning'] case final Map learning) {
      final session = PracticeSession.fromJson(
        learning.cast<String, dynamic>(),
      );
      final answers = session.answers;
      final last = answers.isEmpty ? null : answers.last;
      final title = last == null
          ? 'Bài luyện - Chưa trả lời'
          : 'Bài luyện - Câu ${answers.length} - Yêu cầu ${last.target} - '
                '${last.skipped ? 'Bỏ qua' : 'Nhận ra ${last.predicted} - ${_answerResult(last)}'}';
      return (
        title: title,
        fields: {
          'type': 'Bài luyện',
          'summary':
              '${session.correctCount}/${session.gradedCount} câu đúng · '
              '${session.answers.length}/${session.targets.length} câu đã làm',
          'occurredAt': Timestamp.fromDate(session.startedAt),
          'details': {
            'completed': session.complete,
            'skipped': session.answers.length - session.gradedCount,
            'answers': session.answers
                .map(
                  (answer) => {
                    'target': answer.target,
                    'recognized': answer.predicted,
                    'result': _answerResult(answer),
                  },
                )
                .toList(),
          },
        },
      );
    }
    final deletedAt = record['deletedAt'] as int?;
    final label = String.fromCharCodes(
      (record['label'] as String).replaceAll('/', '-').runes.take(48),
    );
    return (
      title: deletedAt == null
          ? 'Nhận diện - Nhận ra $label'
          : 'Xóa lịch sử - $label',
      fields: {
        'type': deletedAt == null ? 'Nhận diện' : 'Xóa lịch sử',
        'summary': 'Ký hiệu ${record['label']}',
        'occurredAt': Timestamp.fromMillisecondsSinceEpoch(
          deletedAt ?? record['confirmedAt'] as int,
        ),
        'details': {'label': record['label'], 'signCode': record['signCode']},
      },
    );
  }

  String _answerResult(PracticeAnswer answer) {
    if (answer.skipped) return 'Bỏ qua';
    return answer.correct ? 'Đúng' : 'Sai';
  }

  @override
  Future<SyncPage> pull(String? cursor) async {
    var query = events.orderBy('committedAt').orderBy(FieldPath.documentId);
    if (cursor != null && cursor.isNotEmpty) {
      final values = jsonDecode(cursor) as List<dynamic>;
      query = query.startAfter([
        Timestamp(values[0] as int, values[1] as int),
        values[2] as String,
      ]);
    }
    final snapshot = await query
        .limit(101)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final page = snapshot.docs.take(100).toList();
    var next = cursor ?? '';
    if (page.isNotEmpty) {
      final last = page.last;
      final time = last.data()['committedAt'] as Timestamp;
      next = jsonEncode([time.seconds, time.nanoseconds, last.id]);
    }
    return SyncPage(
      records: page
          .map(
            (doc) => (jsonDecode(doc.data()['payload'] as String) as Map)
                .cast<String, Object?>(),
          )
          .toList(),
      cursor: next,
      hasMore: snapshot.docs.length > 100,
    );
  }
}
