import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/recognition/data/model/hand_feature_extractor.dart';

void main() {
  final hand = List<HandPoint>.filled(21, const HandPoint(0, -0.4))
    ..[0] = const HandPoint(0, 0)
    ..[1] = const HandPoint(0.2, -0.2)
    ..[9] = const HandPoint(0, -0.6)
    ..[17] = const HandPoint(-0.2, -0.4);

  test('centers the wrist and aligns landmark 9 to the vertical axis', () {
    final features = extractHandFeatures(hand);
    expect(features, hasLength(42));
    expect(features[0], closeTo(0, 1e-10));
    expect(features[1], closeTo(0, 1e-10));
    expect(features[18], closeTo(0, 1e-10));
    expect(features[19], lessThan(0));
  });

  test('is translation, rotation and scale invariant', () {
    final original = extractHandFeatures(hand);
    final rotated = hand.map((point) {
      const angle = 0.7;
      return HandPoint(
        4 + 3 * (point.x * math.cos(angle) - point.y * math.sin(angle)),
        2 + 3 * (point.x * math.sin(angle) + point.y * math.cos(angle)),
      );
    }).toList();
    final transformed = extractHandFeatures(rotated);
    for (var index = 0; index < 42; index++) {
      expect(transformed[index], closeTo(original[index], 1e-10));
    }
  });

  test('rejects missing or collapsed hand landmarks', () {
    expect(
      () => extractHandFeatures([const HandPoint(0, 0)]),
      throwsArgumentError,
    );
    expect(
      () => extractHandFeatures(List.filled(21, const HandPoint(0, 0))),
      throwsArgumentError,
    );
  });
}
