import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const midnight = Color(0xFF03174C);
  static const moonlight = Color(0xFF9298FC);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final seeded =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF625AC4),
          brightness: brightness,
        ).copyWith(
          secondary: brightness == Brightness.light
              ? const Color(0xFF946000)
              : const Color(0xFFFFCE70),
          secondaryContainer: const Color(0xFFFBE6BC),
          onSecondaryContainer: const Color(0xFF503400),
        );
    final scheme = brightness == Brightness.dark
        ? seeded.copyWith(
            primary: moonlight,
            onPrimary: const Color(0xFF101C4B),
            primaryContainer: const Color(0xFF2A3674),
            onPrimaryContainer: const Color(0xFFF0F1FF),
            surface: const Color(0xFF122452),
            surfaceContainerLowest: const Color(0xFF0C1D49),
            surfaceContainerLow: const Color(0xFF142653),
            surfaceContainer: const Color(0xFF1A2D5E),
            surfaceContainerHigh: const Color(0xFF213568),
            surfaceContainerHighest: const Color(0xFF283D71),
            onSurface: const Color(0xFFF2F3FF),
            onSurfaceVariant: const Color(0xFFBBC5E4),
            outline: const Color(0xFF8696BF),
            outlineVariant: const Color(0xFF3E527E),
          )
        : seeded;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF625AC4),
        brightness: brightness,
      ),
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFFFFBF5)
          : midnight,
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: .08),
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: brightness == Brightness.dark
            ? scheme.primary
            : scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return IconThemeData(
              color: scheme.onSurface.withValues(alpha: .38),
            );
          }
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: brightness == Brightness.dark
                  ? scheme.onPrimary
                  : scheme.onPrimaryContainer,
            );
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        height: 70,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
