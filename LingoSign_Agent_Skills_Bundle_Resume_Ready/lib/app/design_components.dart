import 'package:flutter/material.dart';

/// Coordinated accents with readable ink and muted surfaces in either theme.
abstract final class AppAccents {
  static const colors = [
    Color(0xFF5146B8),
    Color(0xFFB84B18),
    Color(0xFFA52C6B),
    Color(0xFF2860AD),
    Color(0xFF087C70),
  ];
  static Color tint(BuildContext context, Color color) => Color.alphaBlend(
    color.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? .22 : .10,
    ),
    Theme.of(context).colorScheme.surface,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = const Color(0xFF5146B8),
  });
  final String title;
  final String subtitle;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, const Color(0xFF21284F), .35)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}
