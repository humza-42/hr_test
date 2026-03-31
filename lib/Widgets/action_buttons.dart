import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isLoadingBreak;
  final bool checkIn;
  final bool checkOut;
  final bool isOnBreak;
  final bool isDark;
  final Color textColor;
  final VoidCallback? onTakeBreakPressed;
  final VoidCallback? onClockInPressed;
  final VoidCallback? onClockOutPressed;

  const ActionButtons({
    super.key,
    required this.isLoadingBreak,
    required this.checkIn,
    required this.checkOut,
    required this.isOnBreak,
    required this.isDark,
    required this.textColor,
    this.onTakeBreakPressed,
    this.onClockInPressed,
    this.onClockOutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Take Break/End Break Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (isLoadingBreak || !checkIn || checkOut)
                ? null
                : onTakeBreakPressed,
            icon: isLoadingBreak
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Icon(isOnBreak ? Icons.stop_circle : Icons.coffee, size: 22),
            label: Text(
              isOnBreak ? 'End Break' : 'Take Break',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOnBreak ? Colors.green : Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 25), // Increased spacing between button rows
        // Clock In/Out Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (isLoadingBreak || checkIn || checkOut)
                    ? null
                    : onClockInPressed,
                icon: isLoadingBreak
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.arrow_forward, size: 22),
                label: const Text(
                  'Clock In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (checkIn || checkOut)
                      ? Colors.grey
                      : const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20), // Increased horizontal spacing

            Expanded(
              child: Builder(
                builder: (context) {
                  final isDisabled = isLoadingBreak || !checkIn || checkOut;
                  return ElevatedButton.icon(
                    onPressed: isDisabled ? null : onClockOutPressed,
                    icon: isLoadingBreak
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.arrow_back, size: 22),
                    label: const Text(
                      'Clock Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!checkIn || checkOut)
                          ? Colors.grey
                          : const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15), // Added extra bottom spacing
      ],
    );
  }
}
