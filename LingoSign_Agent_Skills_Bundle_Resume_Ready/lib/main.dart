import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/app.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/features/recognition/data/camera/camera_plugin_gateway.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        cameraGatewayProvider.overrideWithValue(CameraPluginGateway()),
      ],
      child: const LingoSignApp(),
    ),
  );
}
