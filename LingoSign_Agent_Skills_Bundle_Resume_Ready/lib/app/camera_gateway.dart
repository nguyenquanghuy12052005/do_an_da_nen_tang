import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/recognition/domain/entities/recognition_prediction.dart';

enum CameraOpenFailure { denied, restricted, noCamera, unavailable }

sealed class CameraOpenResult {
  const CameraOpenResult();
}

final class CameraOpened extends CameraOpenResult {
  const CameraOpened();
}

final class CameraOpenFailed extends CameraOpenResult {
  const CameraOpenFailed(this.reason);

  final CameraOpenFailure reason;
}

/// The preview is a Flutter widget; plugin objects stay inside the adapter.
abstract interface class CameraGateway {
  Future<CameraOpenResult> open();
  Widget? get preview;
  Stream<RecognitionPrediction> get predictions;
  Future<void> close();
}

final cameraGatewayProvider = Provider<CameraGateway>(
  (ref) => throw UnimplementedError('Override cameraGatewayProvider in main'),
);
