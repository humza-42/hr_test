import 'package:flutter/material.dart';

/// A widget that constrains content to a maximum width on desktop screens
/// and centers it horizontally. Maintains full width on mobile/tablet.
class DesktopContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const DesktopContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth > 1024;
        final isTablet = screenWidth > 768 && screenWidth <= 1024;

        // Determine padding based on screen size
        EdgeInsets effectivePadding;
        if (padding != null) {
          effectivePadding = padding!;
        } else {
          if (isDesktop) {
            effectivePadding = const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 20.0,
            );
          } else if (isTablet) {
            effectivePadding = const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            );
          } else {
            effectivePadding = const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            );
          }
        }

        // On desktop, align content to the left with constrained width
        if (isDesktop && screenWidth > maxWidth) {
          return Padding(
            padding: effectivePadding,
            child: Align(
              alignment: Alignment.topLeft, // 👈 FORCE LEFT ALIGNMENT
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          );
        }

        // On mobile/tablet or smaller desktop screens, use full width with padding
        return Padding(padding: effectivePadding, child: child);
      },
    );
  }
}
