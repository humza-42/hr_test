import 'package:flutter/material.dart';

class TimeLoggedChart extends StatelessWidget {
  final String currentTime;
  final String timeLogged;
  final String totalBreak;
  final String currentSession;
  final String remainingHours;
  final double progress;

  const TimeLoggedChart({
    super.key,
    required this.currentTime,
    required this.timeLogged,
    required this.totalBreak,
    required this.currentSession,
    required this.remainingHours,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final progressBgColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Current Time ",
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // Current Time
          Center(
            child: Text(
              currentTime,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Donut Chart
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress, // Use calculated progress
                      strokeWidth: 20,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                      backgroundColor: progressBgColor,
                    ),
                  ),
                  // Dark grey center circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Time Logged',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeLogged,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Summary Stats
          _buildStatRow(
            'TOTAL BREAK',
            totalBreak,
            Colors.amber,
            secondaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'CURRENT SESSION',
            currentSession,
            textColor,
            secondaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'REMAINING HOURS',
            remainingHours,
            const Color.fromARGB(255, 250, 152, 40),
            secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
