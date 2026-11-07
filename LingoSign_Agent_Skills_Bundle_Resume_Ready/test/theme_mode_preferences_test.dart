import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/theme/theme_mode_controller.dart';

void main() {
  test('theme preference survives reopening and rapid changes', () async {
    final directory = await Directory.systemTemp.createTemp('lingosign-theme-');
    addTearDown(() => directory.delete(recursive: true));
    Future<Directory> directoryProvider() async => directory;
    final preferences = ThemeModePreferences(directoryProvider);
    expect(await preferences.read(), ThemeMode.system);

    await Future.wait([
      preferences.write(ThemeMode.light),
      preferences.write(ThemeMode.dark),
    ]);
    expect(
      await ThemeModePreferences(directoryProvider).read(),
      ThemeMode.dark,
    );
  });
}
