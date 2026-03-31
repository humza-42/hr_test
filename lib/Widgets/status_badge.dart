import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool checkIn;
  final bool optimisticOnBreak;
  final String? currentBreakTypeName;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  const StatusBadge({
    super.key,
    required this.checkIn,
    required this.optimisticOnBreak,
    required this.currentBreakTypeName,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor = Colors.green;

    // Determine status based on user state
    if (!checkIn) {
      // User has not clocked in
      statusText = 'No Started';
      statusColor = Colors.grey;
    } else if (optimisticOnBreak && currentBreakTypeName != null) {
      // User is on break - show break type name
      statusText = currentBreakTypeName!;
      statusColor = Colors.orange;
    } else {
      // User is clocked in and not on break - show "Work"
      statusText = 'Work';
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
