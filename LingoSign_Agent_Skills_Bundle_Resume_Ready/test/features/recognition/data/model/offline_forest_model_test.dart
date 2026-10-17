import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/recognition/data/model/offline_forest_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'portable forest matches sklearn probabilities on synthetic vectors',
    () async {
      final model = await OfflineForestModel.load();
      final fixture = jsonDecode(
        File('test/fixtures/model_parity_vectors.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(model.labels, hasLength(29));
      for (final item in fixture['cases'] as List) {
        final testCase = item as Map<String, dynamic>;
        final features = (testCase['features'] as List)
            .map((value) => (value as num).toDouble())
            .toList();
        final expected = (testCase['probabilities'] as List)
            .map((value) => (value as num).toDouble())
            .toList();
        final actual = model.predict(features);
        for (var index = 0; index < expected.length; index++) {
          expect(
            actual.probabilities[index],
            closeTo(expected[index], 0.00001),
          );
        }
        final winner = expected.indexOf(
          expected.reduce((a, b) => a > b ? a : b),
        );
        expect(actual.label, model.labels[winner]);
      }
    },
  );
}
