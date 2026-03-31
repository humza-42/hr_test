import 'package:flutter/material.dart';
import 'package:hr_test/Models/break_types_api_model.dart' as break_types;
import 'package:hr_test/Models/profile_api_model.dart';
import 'package:hr_test/Services/Service_Manager/BreakService/break_types_service.dart'
    as BreakTypesService;
import 'package:hr_test/Services/Service_Manager/ProfileService/profile_service.dart'
    as ProfileService;
import 'package:hr_test/Widgets/Daily_attendance_card/daily_attendance_card_break_type_button.dart';
import 'dart:developer' as developer;

class BreakTypeSelectionDialog extends StatelessWidget {
  final Function(int?, String?) onBreakTypeSelected;

  const BreakTypeSelectionDialog({
    super.key,
    required this.onBreakTypeSelected,
  });

  IconData _getBreakTypeIcon(String? name) {
    if (name == null) return Icons.help_outline;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('meeting')) return Icons.people;
    if (lowerName.contains('official') || lowerName.contains('duty'))
      return Icons.business;
    if (lowerName.contains('prayer')) return Icons.favorite;
    if (lowerName.contains('restroom')) return Icons.wc;
    if (lowerName.contains('cleaning')) return Icons.cleaning_services;
    if (lowerName.contains('maintenance')) return Icons.build;
    if (lowerName.contains('sanitization') ||
        lowerName.contains('sanitisation'))
      return Icons.star_outline;
    if (lowerName.contains('equipment') || lowerName.contains('setup'))
      return Icons.settings;
    if (lowerName.contains('inventory')) return Icons.inventory_2;
    if (lowerName.contains('inspection') || lowerName.contains('area'))
      return Icons.remove_red_eye;
    if (lowerName.contains('documentation') || lowerName.contains('document'))
      return Icons.description;
    if (lowerName.contains('training')) return Icons.school;
    if (lowerName.contains('briefing') || lowerName.contains('team'))
      return Icons.groups;
    if (lowerName.contains('extra')) return Icons.add;
    if (lowerName.contains('lunch')) return Icons.restaurant;

    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 550),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future:
              Future.wait([
                BreakTypesService.AuthService.getBreakTypes(),
                ProfileService.AuthService.getProfile(),
              ]).then((results) async {
                final profileAPI = results[1] as GetProfileAPI;

                return {
                  'breakTypes': results[0] as break_types.BreakTypesAPI,
                  'profile': profileAPI,
                };
              }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load break types',
                        style: TextStyle(color: textColor, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!['breakTypes'] == null ||
                (snapshot.data!['breakTypes'] as break_types.BreakTypesAPI)
                        .data ==
                    null ||
                (snapshot.data!['breakTypes'] as break_types.BreakTypesAPI)
                    .data!
                    .isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No break types available',
                    style: TextStyle(color: textColor),
                  ),
                ),
              );
            }

            final breakTypesAPI =
                snapshot.data!['breakTypes'] as break_types.BreakTypesAPI;
            final profileAPI = snapshot.data!['profile'] as GetProfileAPI;
            final breakTypes = breakTypesAPI.data!;

            // Filter duplicate lunch breaks - keep only the first one
            final breakTimeTypesAll = breakTypes
                .where((bt) => bt.professional != true)
                .toList();

            int lunchBreakStartHour = 14; // 2:00 PM default for boys
            int lunchBreakStartMinute = 0;
            int lunchBreakEndHour = 15; // 3:00 PM default for boys
            int lunchBreakEndMinute = 0;
            String lunchBreakStartTime = '2:00 PM'; // Default for boys
            String lunchBreakEndTime = '3:00 PM'; // Default for boys

            // Debug: Log profile API data
            developer.log(
              '[Break Type Dialog] Profile API data: ${profileAPI.data != null ? "exists" : "null"}',
              name: 'DailyAttendanceCard',
            );
            if (profileAPI.data != null) {
              developer.log(
                '[Break Type Dialog] Profile gender field: ${profileAPI.data!.gender} (type: ${profileAPI.data!.gender?.runtimeType})',
                name: 'DailyAttendanceCard',
              );
            }

            bool isFemale = false;
            bool isMale = false;

            // Check if gender data exists and is not empty
            final hasGenderData =
                profileAPI.data != null &&
                profileAPI.data!.gender != null &&
                profileAPI.data!.gender.toString().trim().isNotEmpty;

            if (hasGenderData) {
              final rawGender = profileAPI.data!.gender;
              final genderStr = rawGender.toString().trim();

              // Debug: Log raw gender value
              developer.log(
                '[Break Type Dialog] Raw gender value: "$rawGender" (type: ${rawGender.runtimeType}, string: "$genderStr")',
                name: 'DailyAttendanceCard',
              );

              // Try to parse as number first (handle string numbers like "0", "1")
              int? genderNum;
              try {
                final genderStr = rawGender.toString().trim();
                genderNum = int.tryParse(genderStr);
              } catch (e) {
                // Not a number, continue with string matching
              }

              if (genderNum != null) {
                if (genderNum == 0) {
                  isFemale = true;
                  developer.log(
                    '[Break Type Dialog] ✓ Detected female from numeric value: 0',
                    name: 'DailyAttendanceCard',
                  );
                } else if (genderNum == 1) {
                  isMale = true;
                  developer.log(
                    '[Break Type Dialog] ✓ Detected male from numeric value: 1',
                    name: 'DailyAttendanceCard',
                  );
                }
              } else {
                // Check string values (case-insensitive, partial matching)
                final gender = genderStr.toLowerCase();

                // Female variations - check if string contains female indicators
                if (gender.contains('female') ||
                    gender.contains('girl') ||
                    gender == 'f' ||
                    gender.contains('fem') ||
                    gender.contains('woman') ||
                    gender.contains('women') ||
                    gender == '0') {
                  isFemale = true;
                  developer.log(
                    '[Break Type Dialog] ✓ Detected female from string: "$gender"',
                    name: 'DailyAttendanceCard',
                  );
                }
                // Male variations - check if string contains male indicators
                else if (gender.contains('male') ||
                    gender.contains('boy') ||
                    gender == 'm' ||
                    gender.contains('man') ||
                    gender.contains('men') ||
                    gender == '1') {
                  isMale = true;
                  developer.log(
                    '[Break Type Dialog] ✓ Detected male from string: "$gender"',
                    name: 'DailyAttendanceCard',
                  );
                } else {
                  developer.log(
                    '[Break Type Dialog] ✗ Unknown gender format: "$gender"',
                    name: 'DailyAttendanceCard',
                  );
                }
              }
            } else {
              developer.log(
                '[Break Type Dialog] ✗ No gender data available (data: ${profileAPI.data != null}, gender: ${profileAPI.data?.gender})',
                name: 'DailyAttendanceCard',
              );
            }

            // Set lunch break times based on detected gender
            if (isFemale) {
              lunchBreakStartHour = 13; // 1:30 PM for girls
              lunchBreakStartMinute = 30;
              lunchBreakEndHour = 14; // 2:30 PM for girls
              lunchBreakEndMinute = 30;
              lunchBreakStartTime = '1:30 PM';
              lunchBreakEndTime = '2:30 PM';
              developer.log(
                '[Break Type Dialog] ✓ Set lunch break times for FEMALE: $lunchBreakStartTime to $lunchBreakEndTime',
                name: 'DailyAttendanceCard',
              );
            } else if (isMale) {
              lunchBreakStartHour = 14; // 2:00 PM for boys
              lunchBreakStartMinute = 0;
              lunchBreakEndHour = 15; // 3:00 PM for boys
              lunchBreakEndMinute = 0;
              lunchBreakStartTime = '2:00 PM';
              lunchBreakEndTime = '3:00 PM';
              developer.log(
                '[Break Type Dialog] ✓ Set lunch break times for MALE: $lunchBreakStartTime to $lunchBreakEndTime',
                name: 'DailyAttendanceCard',
              );
            } else {
              developer.log(
                '[Break Type Dialog] ✗ Gender not recognized, using DEFAULT (male) timings: $lunchBreakStartTime to $lunchBreakEndTime',
                name: 'DailyAttendanceCard',
              );
            }

            // Get current time and check if it's within lunch break time window
            final now = DateTime.now();
            // Create DateTime objects for start and end of lunch window (using today's date)
            final lunchStart = DateTime(
              now.year,
              now.month,
              now.day,
              lunchBreakStartHour,
              lunchBreakStartMinute,
            );
            final lunchEnd = DateTime(
              now.year,
              now.month,
              now.day,
              lunchBreakEndHour,
              lunchBreakEndMinute,
            );
            final nowMs = now.millisecondsSinceEpoch;
            final startMs = lunchStart.millisecondsSinceEpoch;
            final endMs = lunchEnd.millisecondsSinceEpoch;
            final isLunchTime = nowMs >= startMs && nowMs <= endMs;

            // Debug logging with detailed time window comparison
            developer.log(
              '[Break Type Dialog] Time window check: '
              'Current: ${now.hour}:${now.minute.toString().padLeft(2, '0')}, '
              'Lunch Window: ${lunchBreakStartHour}:${lunchBreakStartMinute.toString().padLeft(2, '0')} to ${lunchBreakEndHour}:${lunchBreakEndMinute.toString().padLeft(2, '0')}, '
              'IsLunchTime: $isLunchTime, '
              'Current time (ms): $nowMs, Start (ms): $startMs, End (ms): $endMs, '
              'Within window: ${nowMs >= startMs && nowMs <= endMs}',
              name: 'DailyAttendanceCard',
            );

            List<break_types.Data> breakTimeTypes = [];
            bool lunchBreakAdded = false;
            for (var bt in breakTimeTypesAll) {
              final name = (bt.name ?? '').toLowerCase();
              final isLunch = name.contains('lunch');
              final isExtra = name.contains('extra');

              // Debug logging for each break type
              developer.log(
                '[Break Type Dialog] Processing: ${bt.name}, isLunch: $isLunch, isExtra: $isExtra, '
                'lunchBreakAdded: $lunchBreakAdded, isLunchTime: $isLunchTime',
                name: 'DailyAttendanceCard',
              );

              if (isLunch) {
                // Only add lunch break if it's the first one AND it's exactly lunch time
                if (!lunchBreakAdded && isLunchTime) {
                  developer.log(
                    '[Break Type Dialog] ✓ Adding lunch break: ${bt.name} '
                    '(lunchBreakAdded: $lunchBreakAdded, isLunchTime: $isLunchTime)',
                    name: 'DailyAttendanceCard',
                  );
                  breakTimeTypes.add(bt);
                  lunchBreakAdded = true;
                } else {
                  final reason = lunchBreakAdded
                      ? 'duplicate lunch break'
                      : 'not lunch time (isLunchTime: $isLunchTime)';
                  developer.log(
                    '[Break Type Dialog] ✗ Skipping lunch break: ${bt.name} - Reason: $reason',
                    name: 'DailyAttendanceCard',
                  );
                  // Explicitly do NOT add lunch break - it should be filtered out
                }
              } else if (isExtra) {
                // Only add extra break if it's NOT lunch time
                if (!isLunchTime) {
                  developer.log(
                    '[Break Type Dialog] ✓ Adding extra break: ${bt.name} '
                    '(isLunchTime: $isLunchTime)',
                    name: 'DailyAttendanceCard',
                  );
                  breakTimeTypes.add(bt);
                } else {
                  developer.log(
                    '[Break Type Dialog] ✗ Skipping extra break: ${bt.name} - Reason: it is lunch time (isLunchTime: $isLunchTime)',
                    name: 'DailyAttendanceCard',
                  );
                  // Explicitly do NOT add extra break during lunch time
                }
              } else {
                // Add other non-lunch, non-extra break types (always show these)
                developer.log(
                  '[Break Type Dialog] ✓ Adding other break type: ${bt.name}',
                  name: 'DailyAttendanceCard',
                );
                breakTimeTypes.add(bt);
              }
            }

            final professionalActivities = breakTypes
                .where((bt) => bt.professional == true)
                .toList();

            int? selectedProfessionalIndex;
            int? selectedBreakTimeIndex;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                // Check if it's desktop based on screen width
                final screenWidth = MediaQuery.of(context).size.width;
                final isDesktop = screenWidth > 768; // Desktop threshold

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with title and close button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Break Type',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Professional Activities Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Professional Activities (Not counted as break time)',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isDesktop ? 4 : 3,
                                    crossAxisSpacing: isDesktop ? 16 : 12,
                                    mainAxisSpacing: isDesktop ? 16 : 16,
                                    childAspectRatio: isDesktop ? 1.5 : 0.65,
                                  ),
                              itemCount: professionalActivities.length,
                              itemBuilder: (context, index) {
                                final breakType = professionalActivities[index];
                                final isSelected =
                                    selectedProfessionalIndex == index;
                                return BreakTypeButton(
                                  name: breakType.name ?? 'Unknown',
                                  icon: _getBreakTypeIcon(breakType.name),
                                  isProfessional: true,
                                  isSelected: isSelected,
                                  isDark: isDark,
                                  isDesktop: isDesktop,
                                  onTap: () {
                                    setDialogState(() {
                                      selectedProfessionalIndex = index;
                                      selectedBreakTimeIndex = null;
                                    });
                                    Future.delayed(
                                      const Duration(milliseconds: 200),
                                      () {
                                        Navigator.of(context).pop();
                                        onBreakTypeSelected(
                                          breakType.id,
                                          breakType.name,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            // Break Time Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Break Time (Counted as break time)',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLunchTime
                                  ? 'Lunch break is available from $lunchBreakStartTime to $lunchBreakEndTime.'
                                  : 'Lunch break will be available from $lunchBreakStartTime to $lunchBreakEndTime.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (breakTimeTypes.isNotEmpty)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isDesktop ? 4 : 3,
                                      crossAxisSpacing: isDesktop ? 16 : 12,
                                      mainAxisSpacing: isDesktop ? 16 : 16,
                                      childAspectRatio: isDesktop ? 1.5 : 0.65,
                                    ),
                                itemCount: breakTimeTypes.length,
                                itemBuilder: (context, index) {
                                  final breakType = breakTimeTypes[index];
                                  final isSelected =
                                      selectedBreakTimeIndex == index;
                                  return BreakTypeButton(
                                    name: breakType.name ?? 'Unknown',
                                    icon: _getBreakTypeIcon(breakType.name),
                                    isProfessional: false,
                                    isSelected: isSelected,
                                    isDark: isDark,
                                    isDesktop: isDesktop,
                                    onTap: () {
                                      setDialogState(() {
                                        selectedBreakTimeIndex = index;
                                        selectedProfessionalIndex = null;
                                      });
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () {
                                          Navigator.of(context).pop();
                                          onBreakTypeSelected(
                                            breakType.id,
                                            breakType.name,
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
