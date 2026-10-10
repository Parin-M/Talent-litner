import 'package:flutter/material.dart';

/// Flat, edge-aligned tile inspired by Windows Phone's Metro design.
/// Kept as a shared widget so every feature uses the same lightweight surface.
class AnimatedGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedGlassCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: BorderDirectional(
          start: BorderSide(color: onTap == null ? scheme.outlineVariant : scheme.primary, width: onTap == null ? 1 : 4),
          top: BorderSide(color: scheme.outlineVariant, width: 1),
          end: BorderSide(color: scheme.outlineVariant, width: 1),
          bottom: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: child,
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}

class PageReveal extends StatelessWidget {
  final Widget child;
  const PageReveal({super.key, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 6 * (1 - value)), child: child),
        ),
        child: child,
      );
}
