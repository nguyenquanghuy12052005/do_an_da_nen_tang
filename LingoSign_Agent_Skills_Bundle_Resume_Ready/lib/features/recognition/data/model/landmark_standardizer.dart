/// Applies the per-feature Z-score step used by the supplied RF notebook.
/// Input is already extracted as [x0, y0, ..., x20, y20].
class LandmarkStandardizer {
  LandmarkStandardizer({required List<double> mean, required List<double> std})
    : _mean = List<double>.unmodifiable(mean),
      _std = List<double>.unmodifiable(std) {
    if (_mean.length != featureCount || _std.length != featureCount) {
      throw ArgumentError('Expected $featureCount mean and std values');
    }
    if (_mean.any((value) => !value.isFinite) ||
        _std.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Normalization parameters must be finite; std > 0');
    }
  }

  static const featureCount = 42;

  final List<double> _mean;
  final List<double> _std;

  List<double> transform(List<double> features) {
    if (features.length != featureCount ||
        features.any((value) => !value.isFinite)) {
      throw ArgumentError('Expected $featureCount finite landmark features');
    }
    return List<double>.generate(
      featureCount,
      (index) => (features[index] - _mean[index]) / _std[index],
      growable: false,
    );
  }
}
