import 'dart:math' as math;

/// The 2D coordinates returned by a hand-landmark detector, in index order.
class HandPoint {
  const HandPoint(this.x, this.y);

  final double x;
  final double y;
}

/// Produces [x0, y0, ..., x20, y20] for the supplied 42-feature model.
///
/// The original CSV capture script was not supplied. Wrist origin, middle-MCP
/// alignment and radius scaling are inferred from the fitted scaler (features
/// 0, 1 and 18 are effectively zero); this mapping needs real-data validation.
List<double> extractHandFeatures(List<HandPoint> landmarks) {
  if (landmarks.length != 21 ||
      landmarks.any((point) => !point.x.isFinite || !point.y.isFinite)) {
    throw ArgumentError('Expected 21 finite hand landmarks');
  }

  final wrist = landmarks[0];
  final dx9 = landmarks[9].x - wrist.x;
  final dy9 = landmarks[9].y - wrist.y;
  final axisLength = math.sqrt(dx9 * dx9 + dy9 * dy9);
  if (axisLength < 1e-8) {
    throw ArgumentError('Hand axis is too short');
  }

  var scale = 0.0;
  for (final point in landmarks) {
    final dx = point.x - wrist.x;
    final dy = point.y - wrist.y;
    scale = math.max(scale, math.sqrt(dx * dx + dy * dy));
  }
  if (scale < 1e-8) throw ArgumentError('Hand is too small');

  // right = (-dy9, dx9), so an upright image hand retains its x direction.
  final rightX = -dy9 / axisLength;
  final rightY = dx9 / axisLength;
  final upX = -dx9 / axisLength;
  final upY = -dy9 / axisLength;
  final result = List<double>.filled(42, 0);
  for (var index = 0; index < 21; index++) {
    final dx = landmarks[index].x - wrist.x;
    final dy = landmarks[index].y - wrist.y;
    result[index * 2] = (dx * rightX + dy * rightY) / scale;
    result[index * 2 + 1] = (dx * upX + dy * upY) / scale;
  }

  // The supplied fitted means place the thumb on +x and the little finger
  // on -x. Canonicalize either camera handedness into that orientation.
  if (result[2] < result[34]) {
    for (var index = 0; index < 21; index++) {
      result[index * 2] = -result[index * 2];
    }
  }
  return result;
}
