import 'package:flutter/material.dart';

/// Responsive two-item row used by generator forms.
///
/// * Tablet / wide (`maxWidth >= breakpoint`): items side by side.
/// * Narrow phone (`maxWidth < breakpoint`): items stacked vertically.
///
/// Keeps the same visual card style — only the layout constraint changes,
/// so fixed-width Rows can no longer overflow on small screens.
class ResponsiveFormRow extends StatelessWidget {
  final Widget first;
  final Widget second;
  final double breakpoint;
  final double spacing;
  final double runSpacing;

  const ResponsiveFormRow({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = 520,
    this.spacing = 12,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth.isFinite && maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: runSpacing),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            SizedBox(width: spacing),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

/// Responsive bottom action bar: side-by-side on wide screens, stacked
/// full-width buttons on narrow phones. Never overflows.
class ResponsiveBottomActions extends StatelessWidget {
  final Widget primary;
  final Widget? secondary;
  final double breakpoint;

  const ResponsiveBottomActions({
    super.key,
    required this.primary,
    this.secondary,
    this.breakpoint = 480,
  });

  @override
  Widget build(BuildContext context) {
    if (secondary == null) return primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth.isFinite && maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              secondary!,
              const SizedBox(height: 10),
              primary,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: secondary!),
            const SizedBox(width: 12),
            Expanded(child: primary),
          ],
        );
      },
    );
  }
}
