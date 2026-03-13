import 'package:flutter/material.dart';

class BreakTypeButton extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isProfessional;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDesktop;

  const BreakTypeButton({
    super.key,
    required this.name,
    required this.icon,
    required this.isProfessional,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's desktop - if yes, use new styling, if no, use original styling
    if (isDesktop) {
      // DESKTOP VERSION: New styling with light background colors
      final backgroundColor = const Color(
        0xFFEFF6FF,
      ); // rgba(239, 246, 255) - light blue
      final textColor = const Color(
        0xFF374151,
      ); // Dark gray text for better readability
      final iconColor = const Color(
        0xFFA1A1AA,
      ); // rgba(161, 161, 170) - gray icons

      // Optional: Add a selected state border
      final borderColor = isSelected
          ? (isProfessional ? Colors.blue[700]! : Colors.red[700]!)
          : Colors.transparent;

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // MOBILE/TABLET VERSION: Original styling
      final backgroundColor = isProfessional
          ? (isSelected ? Colors.blue[700] : Colors.blue[100])
          : (isSelected ? Colors.red[700] : const Color(0xFFDC2626));
      final textColor = isProfessional
          ? (isSelected ? Colors.white : Colors.blue[900]!)
          : Colors.white;
      final iconColor = isProfessional
          ? (isSelected ? Colors.white : Colors.blue[900]!)
          : Colors.white;

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: isProfessional
                        ? Colors.blue[900]!
                        : Colors.red[900]!,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
