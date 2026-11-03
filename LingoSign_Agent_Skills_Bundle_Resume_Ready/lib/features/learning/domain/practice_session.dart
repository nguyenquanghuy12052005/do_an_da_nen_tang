import '../../recognition/domain/entities/recognition_prediction.dart';
import '../../recognition/domain/usecases/recognition_save_policy.dart';

class PracticeAnswer {
  const PracticeAnswer({
    required this.target,
    this.predicted,
    this.confidence,
    required this.at,
  });
  final String target;
  final String? predicted;
  final double? confidence;
  final DateTime at;
  bool get skipped => predicted == null;
  bool get correct => predicted == target;
  Map<String, Object?> toJson() => {
    'target': target,
    'predicted': predicted,
    'confidence': confidence,
    'at': at.toUtc().millisecondsSinceEpoch,
  };
  factory PracticeAnswer.fromJson(Map<String, dynamic> value) => PracticeAnswer(
    target: value['target'] as String,
    predicted: value['predicted'] as String?,
    confidence: (value['confidence'] as num?)?.toDouble(),
    at: DateTime.fromMillisecondsSinceEpoch(value['at'] as int, isUtc: true),
  );
}

class PracticeSession {
  PracticeSession({
    required this.id,
    required this.startedAt,
    required List<String> targets,
    List<PracticeAnswer> answers = const [],
  }) : targets = List.unmodifiable(targets),
       _answers = List.of(answers) {
    if (targets.isEmpty ||
        targets.any((label) => !RegExp(r'^[A-Z]$').hasMatch(label))) {
      throw ArgumentError('Only supported letter labels can be practiced');
    }
    if (answers.length > targets.length) {
      throw ArgumentError('Too many answers');
    }
  }
  final String id;
  final DateTime startedAt;
  final List<String> targets;
  final List<PracticeAnswer> _answers;
  List<PracticeAnswer> get answers => List.unmodifiable(_answers);
  bool get complete => _answers.length == targets.length;
  String? get target => complete ? null : targets[_answers.length];
  int get correctCount => _answers.where((answer) => answer.correct).length;
  int get gradedCount => _answers.where((answer) => !answer.skipped).length;
  bool answer(RecognitionPrediction prediction, DateTime at) {
    if (complete ||
        !RecognitionSavePolicy().isConfident(prediction) ||
        !RegExp(r'^[A-Z]$').hasMatch(prediction.labelId!)) {
      return false;
    }
    _answers.add(
      PracticeAnswer(
        target: target!,
        predicted: prediction.labelId,
        confidence: prediction.confidence,
        at: at,
      ),
    );
    return true;
  }

  void skip(DateTime at) {
    if (!complete) _answers.add(PracticeAnswer(target: target!, at: at));
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toUtc().millisecondsSinceEpoch,
    'targets': targets,
    'answers': _answers.map((answer) => answer.toJson()).toList(),
  };
  factory PracticeSession.fromJson(Map<String, dynamic> value) =>
      PracticeSession(
        id: value['id'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          value['startedAt'] as int,
          isUtc: true,
        ),
        targets: (value['targets'] as List).cast<String>(),
        answers: (value['answers'] as List)
            .map(
              (answer) => PracticeAnswer.fromJson(
                (answer as Map).cast<String, dynamic>(),
              ),
            )
            .toList(),
      );
}

abstract interface class LearningRepository {
  Future<void> save(PracticeSession session);
  Stream<List<PracticeSession>> watchSessions();
}
