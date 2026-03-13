import 'package:flutter/material.dart';
import 'package:hr_system_test/Models/dashboard_api_model.dart';
import 'package:hr_system_test/Models/profile_api_model.dart';

import 'package:hr_system_test/Services/Service_Manager/DashboardService/dashboard_service.dart'
    as DashboardService;
import 'package:hr_system_test/Services/Service_Manager/AttendanceService/clock_in_service.dart'
    as ClockInService;
import 'package:hr_system_test/Services/Service_Manager/AttendanceService/clock_out_service.dart'
    as ClockOutService;
import 'package:hr_system_test/Services/Service_Manager/AttendanceService/start_break_service.dart'
    as StartBreakService;
import 'package:hr_system_test/Services/Service_Manager/AttendanceService/break_end_service.dart'
    as BreakEndService;
import 'package:hr_system_test/Services/Service_Manager/AttendanceService/extra_break_service.dart'
    as ExtraBreakService;
import 'package:hr_system_test/Services/Service_Manager/BreakService/break_types_service.dart'
    as BreakTypesService;
import 'package:hr_system_test/Services/Service_Manager/ProfileService/profile_service.dart'
    as ProfileService;
import 'package:hr_system_test/Services/storage_service.dart';
import 'package:hr_system_test/Widgets/Daily_attendance_card/daily_attendance_card_break_type_button.dart';
import 'package:hr_system_test/Models/break_types_api_model.dart'
    as break_types;
import 'dart:developer' as developer;

class DailyAttendanceCard extends StatefulWidget {
  final VoidCallback? onDataRefresh;
  final Function(DateTime)? onClockIn;
  final VoidCallback? onClockOut;
  final Function(DateTime, String)?
  onBreakEnd; // Updated to include break type name
  final Function(DateTime, String)?
  onBreakStart; // Updated to include break type name

  const DailyAttendanceCard({
    super.key,
    this.onDataRefresh,
    this.onClockIn,
    this.onClockOut,
    this.onBreakEnd,
    this.onBreakStart,
  });

  @override
  State<DailyAttendanceCard> createState() => _DailyAttendanceCardState();
}

class _DailyAttendanceCardState extends State<DailyAttendanceCard>
    with AutomaticKeepAliveClientMixin {
  Future<DashboardAPI>? _dataFuture;
  bool _isLoadingClockIn = false;
  bool _isLoadingClockOut = false;
  bool _isLoadingBreak = false;
  bool _optimisticCheckIn = false;
  bool _optimisticCheckOut = false;
  bool _optimisticOnBreak = false;
  String?
  _currentBreakTypeName; // Track the name of the currently active break type
  DateTime? _clockInTime;
  DateTime? _clockInDate; // Track the date when clock-in happened
  DateTime? _clockOutTime;
  DateTime? _clockOutDate; // Track the date when clock-out happened
  bool _hasInitialized = false; // Track if initialization has completed
  bool _hasClockedBackIn =
      false; // Track if user has clocked back in after clock-out

  @override
  bool get wantKeepAlive => true; // Preserve state across rebuilds (theme changes, navigation)

  @override
  void initState() {
    super.initState();
    // Only create future once - don't recreate on rebuilds
    _dataFuture ??=
        DashboardService.AuthService.getDashboardData()
            as Future<DashboardAPI>?;

    // Prevent multiple initialization attempts if widget is recreated quickly
    if (_hasInitialized) {
      return;
    }

    // Single initialization - fetch all data at once
    Future.wait([
      StorageService.getClockInDate(),
      StorageService.getClockInTime(),
      StorageService.getClockOutDate(),
      StorageService.getClockOutTime(),
      DashboardService.AuthService.getDashboardData(),
    ]).then((results) async {
      // Mark as initialized to prevent multiple attempts
      _hasInitialized = true;
      if (!mounted) return;

      final storedClockInDate = results[0] as DateTime?;
      final storedClockInTime = results[1] as DateTime?;
      final storedClockOutDate = results[2] as DateTime?;
      final storedClockOutTime = results[3] as DateTime?;
      final apiResponse = results[4] as DashboardAPI;
      final apiData = apiResponse.data;
      final apiCheckIn = (apiData?.checkIn ?? '').isNotEmpty;
      final apiCheckOut = (apiData?.checkOut ?? false) as bool;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Check if clock-out was stored today AND clock-in was also today
      // This indicates a break (not real clock-out), so preserve check-in state
      if (storedClockOutDate != null) {
        final clockOutDateOnly = DateTime(
          storedClockOutDate.year,
          storedClockOutDate.month,
          storedClockOutDate.day,
        );

        if (clockOutDateOnly == todayDate && storedClockInDate != null) {
          final clockInDateOnly = DateTime(
            storedClockInDate.year,
            storedClockInDate.month,
            storedClockInDate.day,
          );

          if (clockInDateOnly == todayDate) {
            // Both clock-in and clock-out are today - this was a break, not clock-out
            developer.log(
              '[initState] Detected break (clock-out same day as clock-in), clearing clock-out storage',
              name: 'DailyAttendanceCard',
            );
            // Clear the erroneous clock-out storage
            StorageService.clearClockOutDate();
            StorageService.clearClockOutTime();
            // Treat as if user never clocked out
            setState(() {
              _clockOutDate = null;
              _clockOutTime = null;
              _optimisticCheckOut = false;
              _optimisticCheckIn = true;
              _clockInDate = storedClockInDate;
              _clockInTime = storedClockInTime;
            });
            return; // Initialization complete
          }
        }
      }

      // Check if clock-in date is before today (midnight passed)
      if (storedClockInDate != null) {
        final clockInDateOnly = DateTime(
          storedClockInDate.year,
          storedClockInDate.month,
          storedClockInDate.day,
        );

        if (clockInDateOnly.isBefore(todayDate)) {
          // Midnight has passed - save previous day's record and clear clock-in state
          developer.log(
            '[initState] Midnight passed - saving historical record and clearing clock-in state',
            name: 'DailyAttendanceCard',
          );

          // Save the previous day's record to historical storage
          await StorageService.saveHistoricalAttendance(
            clockInDate: storedClockInDate,
            clockInTime: storedClockInTime,
            clockOutDate: storedClockOutDate,
            clockOutTime: storedClockOutTime,
          );

          // Clear clock-in state to allow new day's clock-in
          StorageService.clearClockInDate();
          StorageService.clearClockInTime();
          if (storedClockOutDate != null) {
            StorageService.clearClockOutDate();
            StorageService.clearClockOutTime();
          }

          if (mounted) {
            setState(() {
              _clockInDate = null;
              _clockInTime = null;
              _clockOutDate = null;
              _clockOutTime = null;
              _optimisticCheckIn = false;
              _optimisticCheckOut = false;
            });
          }

          // Show notification to user about auto-clock-out
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A new day has started. Your previous session has been saved automatically.',
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return; // Initialization complete
        }
      }

      // Normal case: determine check-in state
      if (storedClockInDate != null && storedClockInTime != null) {
        // If we have stored clock-in time, use it regardless of API response
        setState(() {
          _clockInDate = storedClockInDate;
          _clockInTime = storedClockInTime;
          _optimisticCheckIn = true;
          _optimisticCheckOut = false;
        });
      } else if (apiCheckIn && !apiCheckOut) {
        // API confirms user is clocked in but no storage
        setState(() {
          _optimisticCheckIn = true;
          _optimisticCheckOut = false;
        });
      } else if (!apiCheckIn && !apiCheckOut) {
        // API says user is not clocked in and no storage
        setState(() {
          _clockInTime = null;
          _clockInDate = null;
          _clockOutTime = null;
          _clockOutDate = null;
          _optimisticCheckIn = false;
          _optimisticCheckOut = false;
        });
        // Clear storage
        StorageService.clearClockInDate();
        StorageService.clearClockInTime();
        StorageService.clearClockOutDate();
        StorageService.clearClockOutTime();
      } else if (apiCheckOut) {
        // User has clocked out according to API
        setState(() {
          _optimisticCheckIn = false;
          _optimisticCheckOut = true;
        });
      }
    });
  }

  void _refreshData({bool forceRefresh = false}) {
    developer.log(
      '[_refreshData] Called - forceRefresh: $forceRefresh',
      name: 'DailyAttendanceCard',
    );

    if (!forceRefresh) {
      developer.log(
        '[_refreshData] Skipping refresh - not forced',
        name: 'DailyAttendanceCard',
      );
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    bool preserveClockOut = false;
    bool preserveCheckIn = false;
    bool preserveBreak = false;

    if (_clockInTime == null && _clockInDate != null) {
      StorageService.getClockInTime().then((storedTime) {
        if (storedTime != null && mounted) {
          setState(() {
            _clockInTime = storedTime;
          });
        }
      });
    }
    if (_clockOutTime == null && _clockOutDate != null) {
      StorageService.getClockOutTime().then((storedTime) {
        if (storedTime != null && mounted) {
          setState(() {
            _clockOutTime = storedTime;
          });
        }
      });
    }

    if (_optimisticOnBreak) {
      preserveBreak = true;
      // If user is on break, they must be clocked in - always preserve check-in state
      preserveCheckIn = true;
    }
    if (_clockInDate != null && _clockOutDate == null) {
      // User has clocked in and hasn't clocked out - preserve check-in state
      preserveCheckIn = true;
    }

    if (_clockOutDate != null) {
      final clockOutDateOnly = DateTime(
        _clockOutDate!.year,
        _clockOutDate!.month,
        _clockOutDate!.day,
      );
      if (clockOutDateOnly == todayDate) {
        // Clock-out happened today, preserve optimistic state
        preserveClockOut = true;
      } else {
        // Clock-out was on a different day - clear it (new day started, user can clock in again)
        _clockOutDate = null;
        _clockOutTime = null;
        StorageService.clearClockOutDate();
        StorageService.clearClockOutTime();
      }
    } else {
      if (_optimisticCheckIn && !preserveCheckIn) {
        preserveCheckIn = true;
      }
    }

    setState(() {
      // Only recreate future if explicitly refreshing
      _dataFuture =
          DashboardService.AuthService.getDashboardData()
              as Future<DashboardAPI>?;
      // If clock-out date is today, ensure optimistic state is preserved
      if (preserveClockOut && !_optimisticCheckOut) {
        _optimisticCheckOut = true;
        _optimisticCheckIn = false;
      }

      if (preserveCheckIn && !preserveClockOut) {
        _optimisticCheckIn = true;
        // Defensive: Ensure _clockInDate is set if it's not already (shouldn't happen, but be safe)
        if (_clockInDate == null) {
          _clockInDate = todayDate;
        }
      } else if (!preserveCheckIn &&
          !preserveClockOut &&
          _clockInDate != null) {
        _optimisticCheckIn = true;
        preserveCheckIn = true; // Set flag to ensure state is preserved
      }
      if (_clockInDate != null && _clockOutDate == null) {
        // User has clocked in - ensure state is preserved
        _optimisticCheckIn = true;
        // Ensure _clockInTime is preserved (restore from storage if missing)
        if (_clockInTime == null) {
          // Will be restored asynchronously above, but ensure state is set
        }
      }

      if (preserveBreak) {
        _optimisticOnBreak = true;

        if (!_optimisticCheckIn && !preserveClockOut) {
          _optimisticCheckIn = true;
        }
      } else {
        // If not preserving break, clear break type name
        _currentBreakTypeName = null;
      }
    });
  }

  Future<void> _handleClockIn() async {
    // Check if user already clocked out today - prevent multiple clock-ins per day
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_clockOutDate != null) {
      final clockOutDateOnly = DateTime(
        _clockOutDate!.year,
        _clockOutDate!.month,
        _clockOutDate!.day,
      );
      if (clockOutDateOnly == todayDate) {
        // User already clocked out today - prevent clock-in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already clocked out today. You can clock in again tomorrow.',
            ),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoadingClockIn = true;
    });

    try {
      final response = await ClockInService.AuthService.clockIn();
      if (!mounted) return;

      // Capture clock-in time
      final now = DateTime.now();

      bool clockOutToday = false;

      if (_clockOutDate != null) {
        final clockOutDateOnly = DateTime(
          _clockOutDate!.year,
          _clockOutDate!.month,
          _clockOutDate!.day,
        );
        clockOutToday = (clockOutDateOnly == todayDate);
      }

      developer.log(
        '[_handleClockIn] Setting optimistic state: checkIn=true, checkOut=false',
        name: 'DailyAttendanceCard',
      );
      final clockInDate = DateTime(now.year, now.month, now.day);
      setState(() {
        _isLoadingClockIn = false;
        _optimisticCheckIn = true;
        _optimisticOnBreak = false; // Reset break state on clock-in
        _currentBreakTypeName = null; // Clear break type name on clock-in

        if (!clockOutToday) {
          _optimisticCheckOut = false;
        }
        _clockInTime = now; // Store the clock-in time
        _clockInDate = clockInDate; // Store the date
      });
      // Save clock-in date and time to storage for persistence across widget rebuilds
      print('Saving clock-in date: $clockInDate');
      print('Saving clock-in time: $now');
      await StorageService.saveClockInDate(clockInDate);
      await StorageService.saveClockInTime(now);
      // Verify that the data was saved
      final savedDate = await StorageService.getClockInDate();
      final savedTime = await StorageService.getClockInTime();
      print('Saved clock-in date: $savedDate');
      print('Saved clock-in time: $savedTime');
      developer.log(
        '[_handleClockIn] Optimistic state set - _optimisticCheckIn: $_optimisticCheckIn, _optimisticCheckOut: $_optimisticCheckOut',
        name: 'DailyAttendanceCard',
      );

      // Then show snackbar (might trigger rebuild, but optimistic state is already set)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Clocked in successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onClockIn != null) {
        widget.onClockIn!(now);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted && _isLoadingClockIn) {
        setState(() {
          _isLoadingClockIn = false;
        });
      }
    }
  }

  Future<void> _handleClockOut() async {
    setState(() {
      _isLoadingClockOut = true;
    });

    try {
      final response = await ClockOutService.AuthService.clockOut();
      if (!mounted) return;

      // Capture clock-out time and date
      final now = DateTime.now();
      developer.log(
        '[_handleClockOut] Setting optimistic state: checkIn=false, checkOut=true',
        name: 'DailyAttendanceCard',
      );
      final clockOutDate = DateTime(now.year, now.month, now.day);
      setState(() {
        _isLoadingClockOut = false;
        _optimisticCheckOut = true;
        _optimisticCheckIn = false;
        _clockOutTime = now; // Store the clock-out time
        _clockOutDate =
            clockOutDate; // Store the date (without time) when clock-out happened
        _clockInDate = null; // Clear clock-in date when clocking out
        _clockInTime = null; // Clear clock-in time when clocking out
      });
      // Save clock-out date and time to storage for persistence
      StorageService.saveClockOutDate(clockOutDate);
      StorageService.saveClockOutTime(now);
      // Clear clock-in date and time from storage when clocking out
      StorageService.clearClockInDate();
      StorageService.clearClockInTime();
      developer.log(
        '[_handleClockOut] Optimistic state set - _optimisticCheckIn: $_optimisticCheckIn, _optimisticCheckOut: $_optimisticCheckOut',
        name: 'DailyAttendanceCard',
      );

      // Notify parent to stop timer
      if (widget.onClockOut != null) {
        widget.onClockOut!();
      }

      // Then show snackbar (might trigger rebuild, but optimistic state is already set)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Clocked out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClockOut = false;
        });
      }
    }
  }

  Future<void> _handleStartBreak() async {
    // Show break type selection dialog
    _showBreakTypeSelectionDialog();
  }

  Future<void> _handleEndBreak() async {
    setState(() {
      _isLoadingBreak = true;
    });

    try {
      final response = await BreakEndService.AuthService.endBreak();
      if (!mounted) return;

      // Capture break end time to reset current session
      final breakEndTime = DateTime.now();
      setState(() {
        _isLoadingBreak = false;
        _optimisticOnBreak = false; // Set optimistic break state to false
        _currentBreakTypeName = null; // Clear the break type name
      });

      // Notify parent to reset current session (clock-in time remains unchanged)
      if (widget.onBreakEnd != null) {
        widget.onBreakEnd!(breakEndTime, _currentBreakTypeName ?? '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Break ended successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted && _isLoadingBreak) {
        setState(() {
          _isLoadingBreak = false;
        });
      }
    }
  }

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

  void _showBreakTypeSelectionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 550,
            ), // Reduced height
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
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
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
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
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

                // developer.log(
                //   '[Break Type Dialog] Final breakTimeTypes count: ${breakTimeTypes.length}, '
                //   'Types: ${breakTimeTypes.map((bt) => bt.name).join(", ")}',
                //   name: 'DailyAttendanceCard',
                // );

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
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
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
                                        crossAxisCount: isDesktop
                                            ? 4
                                            : 3, // More columns on desktop
                                        crossAxisSpacing: isDesktop ? 16 : 12,
                                        mainAxisSpacing: isDesktop ? 16 : 16,
                                        childAspectRatio: isDesktop
                                            ? 1.5
                                            : 0.65, // Wider on desktop
                                      ),
                                  itemCount: professionalActivities.length,
                                  itemBuilder: (context, index) {
                                    final breakType =
                                        professionalActivities[index];
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
                                            Navigator.of(dialogContext).pop();
                                            _startBreakWithType(
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isDesktop
                                              ? 4
                                              : 3, // More columns on desktop
                                          crossAxisSpacing: isDesktop ? 16 : 12,
                                          mainAxisSpacing: isDesktop ? 16 : 16,
                                          childAspectRatio: isDesktop
                                              ? 1.5
                                              : 0.65, // Wider on desktop
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
                                              Navigator.of(dialogContext).pop();
                                              _startBreakWithType(
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
      },
    );
  }

  Future<void> _startBreakWithType(
    int? breakTypeId,
    String? breakTypeName,
  ) async {
    setState(() {
      _isLoadingBreak = true;
    });

    try {
      // Check if the selected break type is "Extra Break"
      final isExtraBreak =
          breakTypeName != null &&
          breakTypeName.toLowerCase().contains('extra');

      if (isExtraBreak) {
        // Call extra break API
        final extraBreakResponse =
            await ExtraBreakService.AuthService.markExtraBreak();
        if (!mounted) return;

        // Capture break start time to reset current session
        final breakStartTime = DateTime.now();

        // Update loading state and optimistic break state FIRST
        setState(() {
          _isLoadingBreak = false;
          _optimisticOnBreak = true; // Set optimistic break state to true
          _currentBreakTypeName = breakTypeName; // Store the break type name
          // Ensure check-in state is set when starting break
          if (!_optimisticCheckIn) {
            _optimisticCheckIn = true;
          }
        });

        // Notify parent to reset current session (clock-in time remains unchanged)
        if (widget.onBreakStart != null) {
          widget.onBreakStart!(breakStartTime, breakTypeName ?? 'Extra Break');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              extraBreakResponse.msg ?? 'Extra break marked successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Do NOT refresh dashboard data after marking extra break
        // This prevents the clock-in button from being re-enabled
      } else {
        // Call regular start break API for other break types
        final response = await StartBreakService.AuthService.startBreak();
        if (!mounted) return;

        // Capture break start time to reset current session
        final breakStartTime = DateTime.now();

        // Update loading state and optimistic break state FIRST
        // This ensures button updates immediately, even if snackbar triggers rebuild
        setState(() {
          _isLoadingBreak = false;
          _optimisticOnBreak = true; // Set optimistic break state to true
          _currentBreakTypeName = breakTypeName; // Store the break type name
          // Ensure check-in state is set when starting break
          // User can't be on break without being clocked in
          if (!_optimisticCheckIn) {
            _optimisticCheckIn = true;
          }
        });

        // Notify parent to reset current session (clock-in time remains unchanged)
        if (widget.onBreakStart != null) {
          widget.onBreakStart!(breakStartTime, breakTypeName ?? 'Break');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Break started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Don't refresh automatically - optimistic state is enough
      // The refresh was causing clock-in record to disappear
      // If refresh is needed, it can be triggered manually or after a longer delay
      // Removing automatic refresh prevents state loss
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted && _isLoadingBreak) {
        setState(() {
          _isLoadingBreak = false;
        });
      }
    }
  }

  String _formatTime12Hour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Ensure future exists - create only if null (shouldn't happen, but defensive)
    _dataFuture ??=
        DashboardService.AuthService.getDashboardData()
            as Future<DashboardAPI>?;

    return FutureBuilder<DashboardAPI>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.data == null) {
          return const SizedBox.shrink();
        }

        final apiData = snapshot.data!.data!;
        final apiCheckIn = (apiData.checkIn ?? '').isNotEmpty;
        final apiCheckOut = apiData.checkOut ?? false;
        final apiOnBreak = apiData.onBreak ?? false;

        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        bool forceCheckIn = false;

        if (_clockInDate == null && _clockOutDate == null) {
          // Try to restore clock-in date from storage
          StorageService.getClockInDate().then((storedDate) {
            if (storedDate != null && mounted) {
              setState(() {
                _clockInDate = storedDate;
                // Also restore clock-in time if missing
                if (_clockInTime == null) {
                  StorageService.getClockInTime().then((storedTime) {
                    if (storedTime != null && mounted) {
                      setState(() {
                        _clockInTime = storedTime;
                      });
                    }
                  });
                }
              });
            }
          });
        }

        if (_clockInDate != null && _clockOutDate == null) {
          final clockInDateOnly = DateTime(
            _clockInDate!.year,
            _clockInDate!.month,
            _clockInDate!.day,
          );

          if (clockInDateOnly == todayDate) {
            // User has clocked in today and hasn't clocked out - ensure optimistic state is true
            if (!_optimisticCheckIn) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _optimisticCheckIn = true;
                  });
                }
              });
            }
            if (_clockInTime == null) {
              StorageService.getClockInTime().then((storedTime) {
                if (storedTime != null && mounted) {
                  setState(() {
                    _clockInTime = storedTime;
                  });
                }
              });
            }
            forceCheckIn = true;
          } else {
            // User didn't clock out previous day - treat as not clocked in today
            forceCheckIn = false;
            // Clear stale clock-in state to allow new clock-in
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _optimisticCheckIn = false;
                  _clockInDate = null;
                  _clockInTime = null;
                });
              }
            });
            StorageService.clearClockInDate();
            StorageService.clearClockInTime();
          }
        }

        // Check if API checkIn date is from a previous day
        bool isValidApiCheckIn = apiCheckIn;
        if (apiCheckIn &&
            apiData.checkIn != null &&
            apiData.checkIn!.isNotEmpty) {
          try {
            final apiCheckInDate = DateTime.parse(apiData.checkIn!);
            final apiCheckInDateOnly = DateTime(
              apiCheckInDate.year,
              apiCheckInDate.month,
              apiCheckInDate.day,
            );

            if (apiCheckInDateOnly != todayDate) {
              developer.log(
                '[Debug] API checkIn date (${apiCheckInDateOnly}) is not today (${todayDate}) - ignoring',
                name: 'DailyAttendanceCard',
              );
              isValidApiCheckIn = false;
            }
          } catch (e) {
            developer.log(
              '[Debug] Error parsing API checkIn date: $e',
              name: 'DailyAttendanceCard',
            );
          }
        }

        final checkIn = forceCheckIn || _optimisticCheckIn || isValidApiCheckIn;

        developer.log(
          '[Debug] Clock In Button State:',
          name: 'DailyAttendanceCard',
        );
        developer.log('  - todayDate: $todayDate', name: 'DailyAttendanceCard');
        developer.log(
          '  - _clockInDate: $_clockInDate',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - _clockOutDate: $_clockOutDate',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - forceCheckIn: $forceCheckIn',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - _optimisticCheckIn: $_optimisticCheckIn',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - apiCheckIn: $apiCheckIn',
          name: 'DailyAttendanceCard',
        );
        developer.log('  - checkIn: $checkIn', name: 'DailyAttendanceCard');
        final isOnBreak =
            checkIn &&
            (_optimisticOnBreak
                ? true
                : (_optimisticCheckIn && !_optimisticOnBreak)
                ? false // User just clocked in and break was reset - ignore API
                : apiOnBreak // Use API state otherwise
                  );

        bool forceCheckOut = false;

        // Check if it's past 12:00 AM (midnight) - if yes, clear clock-out state from previous day
        final midnight = DateTime(now.year, now.month, now.day, 0, 0, 0);
        if (now.isAfter(midnight) && _clockOutDate != null) {
          final clockOutDateOnly = DateTime(
            _clockOutDate!.year,
            _clockOutDate!.month,
            _clockOutDate!.day,
          );
          if (clockOutDateOnly != todayDate) {
            // Clock-out was from a previous day - clear it so user can clock in again
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _clockOutDate = null;
                  _clockOutTime = null;
                  _optimisticCheckOut = false;
                });
              }
            });
            // Clear storage as well
            StorageService.clearClockOutDate();
            StorageService.clearClockOutTime();
          }
        }

        if (_clockOutDate != null) {
          final clockOutDateOnly = DateTime(
            _clockOutDate!.year,
            _clockOutDate!.month,
            _clockOutDate!.day,
          );
          if (clockOutDateOnly == todayDate) {
            // Clock-out happened today - FORCE checkOut to true regardless of API or optimistic state
            forceCheckOut = true;
            // Ensure optimistic state matches if it doesn't already
            if (!_optimisticCheckOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _optimisticCheckOut = true;
                    _optimisticCheckIn = false;
                  });
                }
              });
            }
          }
        }
        if (apiCheckIn &&
            !_optimisticCheckIn &&
            !forceCheckOut &&
            !forceCheckIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _optimisticCheckIn = true;
                // Set clock-in date to today if not already set
                if (_clockInDate == null) {
                  _clockInDate = todayDate;
                } else {
                  // If clock-in date exists but is from a different day, update it
                  final storedDate = DateTime(
                    _clockInDate!.year,
                    _clockInDate!.month,
                    _clockInDate!.day,
                  );
                  if (storedDate != todayDate) {
                    _clockInDate = todayDate;
                  }
                }
                // Set clock-in time if not already set
                if (_clockInTime == null) {
                  _clockInTime = now;
                }
              });
            }
          });
        }

        if (forceCheckIn) {
          // User has clocked in - ensure state is preserved
          if (_clockInDate == null) {
            // Restore from storage if missing
            StorageService.getClockInDate().then((storedDate) {
              if (storedDate != null && mounted) {
                setState(() {
                  _clockInDate = storedDate;
                });
              }
            });
          }
          if (_clockInTime == null) {
            // Restore from storage if missing
            StorageService.getClockInTime().then((storedTime) {
              if (storedTime != null && mounted) {
                setState(() {
                  _clockInTime = storedTime;
                });
              }
            });
          }
        }

        if (apiCheckOut &&
            !_optimisticCheckOut &&
            !forceCheckOut &&
            !forceCheckIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _optimisticCheckOut = true;
                _optimisticCheckIn = false;

                _clockInDate = null;
                _clockInTime = null;
                // Set clock-out date to today if not already set
                if (_clockOutDate == null) {
                  _clockOutDate = todayDate;
                } else {
                  // If clock-out date exists but is from a different day, update it
                  final storedDate = DateTime(
                    _clockOutDate!.year,
                    _clockOutDate!.month,
                    _clockOutDate!.day,
                  );
                  if (storedDate != todayDate) {
                    _clockOutDate = todayDate;
                  }
                }
              });
            }
          });
        } else if (!apiCheckOut &&
            _optimisticCheckOut &&
            _clockOutDate != null &&
            !forceCheckOut &&
            !forceCheckIn) {
          final storedDate = DateTime(
            _clockOutDate!.year,
            _clockOutDate!.month,
            _clockOutDate!.day,
          );

          if (storedDate != todayDate) {
            // Clock-out was on a different day, reset optimistic state (new day started)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _optimisticCheckOut = false;
                  _clockOutDate = null;
                  _clockOutTime = null;
                });
              }
            });
          }
        }

        final checkOut = forceCheckOut || _optimisticCheckOut || apiCheckOut;

        // Debug logging
        developer.log(
          '[FutureBuilder Builder] State values:',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - _optimisticCheckIn: $_optimisticCheckIn',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - _optimisticCheckOut: $_optimisticCheckOut',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - apiCheckIn: $apiCheckIn',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - apiCheckOut: $apiCheckOut',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - Combined checkIn: $checkIn (${_optimisticCheckIn} || $apiCheckIn)',
          name: 'DailyAttendanceCard',
        );
        developer.log(
          '  - Combined checkOut: $checkOut (${_optimisticCheckOut} || $apiCheckOut)',
          name: 'DailyAttendanceCard',
        );

        // Format clock in/out times
        // If we have stored times, use them; otherwise fall back to API state
        String clockInTime = _clockInTime != null
            ? _formatTime12Hour(_clockInTime!)
            : (checkIn ? '--:--' : '-');
        String clockOutTime = _clockOutTime != null
            ? _formatTime12Hour(_clockOutTime!)
            : '--:--';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Attendance',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              // Status Badge
              Builder(
                builder: (context) {
                  String statusText;
                  Color statusColor = Colors.green;

                  // Determine status based on user state
                  if (!checkIn) {
                    // User has not clocked in
                    statusText = 'No Started';
                    statusColor = Colors.grey;
                  } else if (_optimisticOnBreak &&
                      _currentBreakTypeName != null) {
                    // User is on break - show break type name
                    statusText = _currentBreakTypeName!;
                    statusColor = Colors.orange;
                  } else {
                    // User is clocked in and not on break - show "Work"
                    statusText = 'Work';
                    statusColor = Colors.green;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                },
              ),
              const SizedBox(height: 20),
              // Clock In/Out Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 219, 234, 254),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLOCK IN',
                            style: TextStyle(
                              color: Color.fromARGB(255, 30, 107, 185),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            clockInTime,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 30, 107, 185),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0B2F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLOCK OUT',
                            style: TextStyle(
                              color: Color.fromARGB(255, 149, 33, 168),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            clockOutTime,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 149, 33, 168),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30), // Increased from 20
              // Action Buttons
              Column(
                children: [
                  // Take Break/End Break Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoadingBreak || !checkIn || checkOut)
                          ? null
                          : (isOnBreak ? _handleEndBreak : _handleStartBreak),
                      icon: _isLoadingBreak
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Icon(
                              isOnBreak ? Icons.stop_circle : Icons.coffee,
                              size: 22,
                            ),
                      label: Text(
                        isOnBreak ? 'End Break' : 'Take Break',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnBreak
                            ? Colors.green
                            : Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ), // Increased from 16
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ), // Increased spacing between button rows
                  // Clock In/Out Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isLoadingClockIn || checkIn || checkOut)
                              ? null
                              : _handleClockIn,
                          icon: _isLoadingClockIn
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (checkIn || checkOut)
                                ? Colors.grey
                                : const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                            ), // Increased from 16
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
                            final isDisabled =
                                _isLoadingClockOut || !checkIn || checkOut;
                            return ElevatedButton.icon(
                              onPressed: isDisabled ? null : _handleClockOut,
                              icon: _isLoadingClockOut
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ), // Increased from 16
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
              ),
            ],
          ),
        );
      },
    );
  }
}
