import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModePreferences {
  ThemeModePreferences(this._directory);

  final Future<Directory> Function() _directory;
  Future<void> _pendingWrite = Future.value();

  Future<File> _file() async => File('${(await _directory()).path}/theme-mode');

  Future<ThemeMode> read() async {
    await _pendingWrite;
    final file = await _file();
    if (!await file.exists()) return ThemeMode.system;
    return switch (await file.readAsString()) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> write(ThemeMode mode) {
    final write = _pendingWrite.then((_) async {
      final file = await _file();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(mode.name, flush: true);
      await temporary.rename(file.path);
    });
    // A failed write must not prevent subsequent writes or reads.
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }
}

final themeModePreferencesProvider = Provider<ThemeModePreferences?>(
  (ref) => null,
);

class ThemeModeController extends Notifier<ThemeMode> {
  bool _changed = false;

  @override
  ThemeMode build() {
    final preferences = ref.read(themeModePreferencesProvider);
    if (preferences != null) unawaited(_restore(preferences));
    return ThemeMode.system;
  }

  Future<void> _restore(ThemeModePreferences preferences) async {
    try {
      final mode = await preferences.read();
      if (ref.mounted && !_changed) state = mode;
    } on Object catch (error) {
      debugPrint('Could not restore theme: ${error.runtimeType}');
    }
  }

  void setDarkMode(bool enabled) {
    _changed = true;
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    final preferences = ref.read(themeModePreferencesProvider);
    if (preferences != null) {
      unawaited(
        preferences.write(mode).catchError((Object error) {
          debugPrint('Could not persist theme: ${error.runtimeType}');
        }),
      );
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
