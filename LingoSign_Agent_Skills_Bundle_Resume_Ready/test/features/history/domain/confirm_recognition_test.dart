import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/dictionary/domain/entities/sign_entry.dart';
import 'package:lingosign_ai/features/dictionary/domain/repositories/sign_dictionary_repository.dart';
import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';
import 'package:lingosign_ai/features/history/domain/repositories/recognition_history_repository.dart';
import 'package:lingosign_ai/features/history/domain/usecases/confirm_recognition.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';

void main() {
  final observedAt = DateTime.utc(2026, 10, 17, 10);
  final confirmedAt = DateTime.utc(2026, 10, 17, 11);

  test(
    'saves a stable supported prediction with injected ID and time',
    () async {
      final dictionary = _FakeDictionary(
        const SignEntry(code: 'HELLO', label: 'Xin chào'),
      );
      final history = _FakeHistory();
      final confirm = ConfirmRecognition(
        dictionary: dictionary,
        history: history,
        nextId: () => 'record-1',
        now: () => confirmedAt,
      );

      final record = await confirm(
        RecognitionPrediction(
          labelId: 'HELLO',
          confidence: 0.9,
          timestamp: observedAt,
          isStable: true,
        ),
      );

      expect(record.id, 'record-1');
      expect(record.signCode, 'HELLO');
      expect(record.label, 'Xin chào');
      expect(record.confirmedAt, confirmedAt);
      expect(history.saved, [record]);
    },
  );

  test('rejects unknown predictions without writing history', () async {
    final history = _FakeHistory();
    final confirm = ConfirmRecognition(
      dictionary: _FakeDictionary(null),
      history: history,
      nextId: () => 'record-1',
      now: () => confirmedAt,
    );

    await expectLater(
      confirm(
        RecognitionPrediction(
          labelId: null,
          confidence: 0,
          timestamp: observedAt,
          isStable: false,
        ),
      ),
      throwsA(
        isA<RecognitionException>().having(
          (error) => error.reason,
          'reason',
          RecognitionFailureReason.unknown,
        ),
      ),
    );
    expect(history.saved, isEmpty);
  });

  test('rejects unstable predictions without writing history', () async {
    final history = _FakeHistory();
    final confirm = ConfirmRecognition(
      dictionary: _FakeDictionary(
        const SignEntry(code: 'HELLO', label: 'Xin chào'),
      ),
      history: history,
      nextId: () => 'record-1',
      now: () => confirmedAt,
    );

    await expectLater(
      confirm(
        RecognitionPrediction(
          labelId: 'HELLO',
          confidence: 0.8,
          timestamp: observedAt,
          isStable: false,
        ),
      ),
      throwsA(
        isA<RecognitionException>().having(
          (error) => error.reason,
          'reason',
          RecognitionFailureReason.unstable,
        ),
      ),
    );
    expect(history.saved, isEmpty);
  });

  test('rejects signs missing from verified dictionary', () async {
    final history = _FakeHistory();
    final confirm = ConfirmRecognition(
      dictionary: _FakeDictionary(null),
      history: history,
      nextId: () => 'record-1',
      now: () => confirmedAt,
    );

    await expectLater(
      confirm(
        RecognitionPrediction(
          labelId: 'UNSUPPORTED',
          confidence: 0.9,
          timestamp: observedAt,
          isStable: true,
        ),
      ),
      throwsA(
        isA<RecognitionException>().having(
          (error) => error.reason,
          'reason',
          RecognitionFailureReason.unsupportedSign,
        ),
      ),
    );
    expect(history.saved, isEmpty);
  });
}

class _FakeDictionary implements SignDictionaryRepository {
  _FakeDictionary(this.entry);

  final SignEntry? entry;

  @override
  Future<SignEntry?> findByCode(String code) async {
    return entry?.code == code ? entry : null;
  }

  @override
  Future<List<SignEntry>> search(String query) async => [];
}

class _FakeHistory implements RecognitionHistoryRepository {
  final saved = <RecognitionRecord>[];

  @override
  Stream<List<RecognitionRecord>> watchHistory() => Stream.value(saved);

  @override
  Future<void> saveConfirmed(RecognitionRecord record) async {
    saved.add(record);
  }

  @override
  Future<void> delete(String id) async {
    saved.removeWhere((record) => record.id == id);
  }
}
