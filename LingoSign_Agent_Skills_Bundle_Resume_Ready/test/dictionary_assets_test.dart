import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled chart contains 36 distinct readable images and supported practice labels', () async {
    final catalog = jsonDecode(
      await rootBundle.loadString('assets/dictionary/catalog.json'),
    ) as Map<String, dynamic>;
    final entries = (catalog['entries'] as List).cast<Map<String, dynamic>>();
    final model = jsonDecode(
      await rootBundle.loadString('assets/model/model.json'),
    ) as Map<String, dynamic>;
    expect(entries.length, 36);
    expect(entries.map((e) => e['code']).toSet().length, 36);
    for (final entry in entries) {
      final bytes = await rootBundle.load(entry['imageAsset'] as String);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 108);
      frame.image.dispose();
      codec.dispose();
      if (entry['category'] == 'Số đếm') {
        expect(entry['modelLabel'], isNull);
      } else {
        expect(model['labels'], contains(entry['modelLabel']));
      }
    }
  });
}
