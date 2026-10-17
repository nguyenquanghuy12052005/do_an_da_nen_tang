import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/recognition/data/model/landmark_standardizer.dart';

void main() {
  test('uses notebook Z-score independently for each of 42 features', () {
    final mean = List<double>.filled(42, 0)..[2] = 3;
    final std = List<double>.filled(42, 1)..[2] = 2;
    final features = List<double>.filled(42, 0)..[2] = 7;
    final result = LandmarkStandardizer(
      mean: mean,
      std: std,
    ).transform(features);

    expect(result, hasLength(42));
    expect(result[2], 2);
    expect(result.where((value) => value != 0), hasLength(1));
  });

  test('rejects malformed parameters and feature vectors', () {
    final valid = List<double>.filled(42, 1);
    expect(
      () => LandmarkStandardizer(mean: [0], std: valid),
      throwsArgumentError,
    );
    expect(
      () => LandmarkStandardizer(
        mean: List<double>.filled(42, 0),
        std: [...valid]..[18] = 0,
      ),
      throwsArgumentError,
    );
    final standardizer = LandmarkStandardizer(
      mean: List<double>.filled(42, 0),
      std: valid,
    );
    expect(() => standardizer.transform([1]), throwsArgumentError);
    expect(
      () => standardizer.transform([...valid]..[0] = double.nan),
      throwsArgumentError,
    );
  });
}
