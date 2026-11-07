import 'package:flutter/material.dart';

/// Coordinated accents with readable ink and muted surfaces in either theme.
abstract final class AppAccents {
  static const colors = [
    Color(0xFF6159BC),
    Color(0xFF9A541C),
    Color(0xFF934D6C),
    Color(0xFF49619C),
    Color(0xFF287364),
  ];
  static Color tint(BuildContext context, Color color) => Color.alphaBlend(
    color.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? .25 : .16,
    ),
    Theme.of(context).colorScheme.surface,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = const Color(0xFF6159BC),
    this.icon = Icons.auto_awesome_outlined,
    this.margin = const EdgeInsets.fromLTRB(20, 16, 20, 4),
  });
  final String title;
  final String subtitle;
  final Color accent;
  final EdgeInsetsGeometry margin;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppAccents.tint(context, accent),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AccentIcon(icon, accent: accent),
        ],
      ),
    );
  }
}

class PanelHeading extends StatelessWidget {
  const PanelHeading(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Semantics(
      header: true,
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

class AccentIcon extends StatelessWidget {
  const AccentIcon(this.icon, {super.key, required this.accent});
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppAccents.tint(context, accent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(
          icon,
          size: 20,
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.onSurface
              : accent,
        ),
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
