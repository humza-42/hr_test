import 'dart:async';
import 'package:flutter/material.dart';

import 'package:hr_system_test/Services/Service_Manager/DashboardService/dashboard_service.dart'
    as DashboardService;

import 'package:hr_system_test/Models/dashboard_api_model.dart';
import 'package:hr_system_test/Services/storage_service.dart';
import 'package:hr_system_test/Widgets/Daily_attendance_card/daily_attendance_card.dart';
import 'package:hr_system_test/Widgets/DashBoard_Overview/time_logged_chart.dart';
import 'package:hr_system_test/Widgets/desktop_container.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview>
    with AutomaticKeepAliveClientMixin {
  late Future<DashboardAPI> _dataFuture;
  DateTime _currentMonth = DateTime.now();
  DateTime? _clockInTime;
  DateTime?
  _currentSessionStartTime; // Tracks current work session start (resets when break starts/ends)
  DateTime? _breakStartTime; // Tracks when the current break started
  Timer? _currentTimeTimer;
  String _currentTime = '--:--:-- --';
  String _timeLogged = '--:--';
  bool _isRestoringClockInTime =
      false; // Flag to prevent multiple simultaneous restoration attempts
  bool _isOnBreak = false; // Track if user is currently on break
  Duration _totalBreakTime = Duration
      .zero; // Track total break time for current day (including all breaks)
  Duration _extraBreakTime = Duration
      .zero; // Track only extra break time (for remaining hours calculation)
  String? _currentBreakTypeName; // Track the current break type name
  DateTime?
  _remainingHoursStartTime; // Track when remaining hours started (for accurate countdown)
  DateTime?
  _lastBreakEndTime; // Track when last break ended for remaining hours calculation
  // Store the last calculated remaining hours to freeze during non-lunch breaks
  String _frozenRemainingHours = '08:00:00';
  bool _hasFrozenRemainingHours = false;
  // Track if current break is an extra break
  bool _isExtraBreak = false;
  // Store the last calculated time logged to freeze during extra breaks
  String _frozenTimeLogged = '--:--';
  bool _hasFrozenTimeLogged = false;
  // Track break start time for each break to calculate duration
  DateTime? _currentBreakPeriodStartTime;
  // Store total break time as a string for real-time display
  String _totalBreakDisplay = '00:00:00';

  @override
  bool get wantKeepAlive => true; // Preserve state across rebuilds (screen changes, navigation)

  @override
  void initState() {
    super.initState();
    _dataFuture = DashboardService.AuthService.getDashboardData();

    // IMMEDIATELY restore clock-in time from storage (sync fallback)
    // This prevents time reset during hot reload
    _restoreClockInTimeFromStorage();

    // Check API status to determine if user is currently clocked in
    // This runs in background to validate the stored time
    DashboardService.AuthService.getDashboardData().then((apiResponse) {
      if (!mounted) return;

      final apiData = apiResponse.data;
      final apiCheckIn = apiData?.checkIn?.isNotEmpty == true;

      // Only restore clock-in time if API confirms user is clocked in
      // This prevents showing stale data from previous sessions
      if (apiCheckIn) {
        // API confirms user is clocked in - restore from storage if not already done
        StorageService.getClockInTime().then((storedTime) {
          if (mounted && storedTime != null && _clockInTime == null) {
            setState(() {
              _clockInTime = storedTime;
              _currentSessionStartTime = storedTime;
              _frozenRemainingHours = '08:00:00';
              _hasFrozenRemainingHours = false;
              _updateTotalBreakDisplay();
            });
          }
        });
      } else {
        // API says user is NOT clocked in - ensure state is cleared
        setState(() {
          _clockInTime = null;
          _currentSessionStartTime = null;
          _frozenRemainingHours = '08:00:00';
          _hasFrozenRemainingHours = false;
          _totalBreakDisplay = '00:00:00';
        });
        StorageService.clearClockInTime();
        StorageService.clearClockInDate();
      }
    });

    // Initialize timer for real-time current time updates
    _currentTimeTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (mounted) {
        final now = DateTime.now();

        // If _clockInTime is null but we have it from storage (hot reload), restore it
        if (_clockInTime != null &&
            _currentSessionStartTime == null &&
            !_isOnBreak) {
          setState(() {
            _currentSessionStartTime = _clockInTime;
          });
        }

        // If _clockInTime is null, first check local storage before API
        if (_clockInTime == null && !_isRestoringClockInTime) {
          _isRestoringClockInTime = true;
          try {
            // First check local storage for clock-in time
            final storedTime = await StorageService.getClockInTime();
            if (storedTime != null && mounted) {
              // If we have stored time, use it without checking API
              setState(() {
                _clockInTime = storedTime;
                _currentSessionStartTime = storedTime;
                _updateTotalBreakDisplay();
              });
            } else {
              // If no stored time, check API to see if user is clocked in
              final apiResponse =
                  await DashboardService.AuthService.getDashboardData();
              final apiData = apiResponse.data;
              final apiCheckIn = apiData?.checkIn?.isNotEmpty == true;

              if (apiCheckIn && mounted) {
                // API confirms user is clocked in but no storage - this shouldn't happen
                // but handle it gracefully
              }
            }
          } catch (e) {
            // Ignore errors during restoration
          } finally {
            _isRestoringClockInTime = false;
          }
        }

        // In initState, update the timer logic:
        if (mounted) {
          setState(() {
            // Update Current Time in 12-hour format
            _currentTime = _formatTime12Hour(now, includeSeconds: true);

            // FIXED: Time Logged should STOP during extra breaks
            if (_isOnBreak && _isExtraBreak) {
              // EXTRA BREAK: Use frozen time logged value
              if (_hasFrozenTimeLogged) {
                _timeLogged = _frozenTimeLogged;
              }
            } else if (_clockInTime != null) {
              // PROFESSIONAL BREAK or WORKING: Show total time since clock-in
              // Use _clockInTime directly to ensure timer continues continuously
              final elapsed = now.difference(_clockInTime!);
              _timeLogged = _formatElapsedTime(elapsed);
            } else {
              _timeLogged = '--:--';
            }

            // Update Total Break display in real-time
            _updateTotalBreakDisplay();
          });
        }
      }
    });
  }

  // Update total break display with current time if on break
  void _updateTotalBreakDisplay() {
    final now = DateTime.now();
    Duration currentTotalBreak = _totalBreakTime;

    // If currently on break, add the current break duration to total
    if (_isOnBreak && _currentBreakPeriodStartTime != null) {
      final currentBreakDuration = now.difference(
        _currentBreakPeriodStartTime!,
      );
      currentTotalBreak = _totalBreakTime + currentBreakDuration;
    }

    _totalBreakDisplay = _formatElapsedTime(currentTotalBreak);
  }

  // Restore clock-in time from storage immediately
  // This prevents time reset during hot reload by loading from storage synchronously
  Future<void> _restoreClockInTimeFromStorage() async {
    print('Restoring clock-in time from storage...');
    try {
      final storedTime = await StorageService.getClockInTime();
      print('Stored clock-in time: $storedTime');
      if (mounted && storedTime != null) {
        print('Restoring clock-in time: $storedTime');
        setState(() {
          _clockInTime = storedTime;
          _currentSessionStartTime = storedTime;
          _frozenRemainingHours = '08:00:00';
          _hasFrozenRemainingHours = false;
          _updateTotalBreakDisplay();
        });
      } else {
        print('No stored clock-in time found');
      }
    } catch (e) {
      print('Error restoring clock-in time: $e');
    }
  }

  @override
  void dispose() {
    _currentTimeTimer?.cancel();
    super.dispose();
  }

  void _refreshDashboardData() {
    setState(() {
      _dataFuture = DashboardService.AuthService.getDashboardData();
    });
  }

  void _setClockInTime(DateTime time) async {
    await StorageService.saveClockInTime(time);
    setState(() {
      _clockInTime = time;
      _currentSessionStartTime =
          time; // Initialize session start time to clock-in time
      _totalBreakTime =
          Duration.zero; // Reset total break time when clocking in
      _extraBreakTime =
          Duration.zero; // Reset extra break time when clocking in
      _breakStartTime = null; // Clear break start time
      _isOnBreak = false; // Reset break state
      _currentBreakTypeName = null; // Clear break type name
      _remainingHoursStartTime =
          time; // Start remaining hours countdown from clock-in time
      _lastBreakEndTime = null; // Clear last break end time
      _frozenRemainingHours = '08:00:00'; // Reset frozen remaining hours
      _hasFrozenRemainingHours = false;
      _currentBreakPeriodStartTime = null;
      _isExtraBreak = false;
      _totalBreakDisplay = '00:00:00';
      // Don't format here - timer will handle it
    });
  }

  void _stopTimer() async {
    await StorageService.clearClockInTime();
    setState(() {
      _clockInTime =
          null; // Stop timer - time logged will freeze at current value
      _currentSessionStartTime =
          null; // Clear session start time when clocking out
      _totalBreakTime =
          Duration.zero; // Reset total break time when clocking out
      _extraBreakTime =
          Duration.zero; // Reset extra break time when clocking out
      _breakStartTime = null; // Clear break start time
      _isOnBreak = false; // Reset break state
      _frozenRemainingHours = '08:00:00'; // Reset frozen remaining hours
      _hasFrozenRemainingHours = false;
      _currentBreakPeriodStartTime = null;
      _isExtraBreak = false;
      _totalBreakDisplay = '00:00:00';
    });
  }

  void _startBreak(DateTime time, String? breakTypeName) {
    // Start a new break session
    final isExtraBreak = _isExtraBreakType(breakTypeName ?? '');
    final isProfessionalBreak = !isExtraBreak;

    setState(() {
      // Record break start time for duration calculation
      _currentBreakPeriodStartTime = time;
      _breakStartTime = time;
      _isOnBreak = true;
      _currentBreakTypeName = breakTypeName ?? 'Break';
      _isExtraBreak = isExtraBreak;

      // Reset session start time for ALL breaks (original behavior)
      _currentSessionStartTime = null;

      if (isExtraBreak) {
        // EXTRA BREAK: Freeze remaining hours and time logged
        if (_clockInTime != null) {
          // Calculate and freeze remaining hours at break start for EXTRA BREAK ONLY
          final now = DateTime.now();
          final elapsed = now.difference(_clockInTime!);
          final elapsedHours = elapsed.inMilliseconds / 3600000.0;
          final breakHours = _extraBreakTime.inMilliseconds / 3600000.0;
          final netWorkingHours = elapsedHours - breakHours;

          const double targetHours = 8.0;
          if (netWorkingHours < targetHours && netWorkingHours >= 0) {
            final remainingMs = ((targetHours - netWorkingHours) * 3600000.0)
                .round();
            if (remainingMs > 0 && remainingMs < 28800000) {
              final remainingDuration = Duration(milliseconds: remainingMs);
              _frozenRemainingHours = _formatElapsedTime(remainingDuration);
              _hasFrozenRemainingHours = true;
            }
          } else if (netWorkingHours >= targetHours) {
            _frozenRemainingHours = '00:00:00';
            _hasFrozenRemainingHours = true;
          }

          // Freeze time logged at break start
          _frozenTimeLogged = _formatElapsedTime(elapsed);
          _hasFrozenTimeLogged = true;
        }
      } else {
        // PROFESSIONAL BREAK: Do NOT freeze remaining hours or time logged (keep timers running)
      }

      // Update total break display immediately
      _updateTotalBreakDisplay();
    });
  }

  void _resetSessionAfterBreak(DateTime time, String? breakTypeName) {
    // Reset current session start time to current time when break ends
    // Keep _clockInTime unchanged (original clock-in time)
    // Accumulate break time to total break time for ALL breaks
    final actualBreakTypeName = breakTypeName ?? 'Break';
    final isExtraBreak = _isExtraBreakType(actualBreakTypeName);
    final isProfessionalBreak = !isExtraBreak;

    if (_breakStartTime != null && _currentBreakPeriodStartTime != null) {
      // Calculate break duration and add to total break time
      final breakDuration = time.difference(_currentBreakPeriodStartTime!);

      setState(() {
        // Add break duration to total break time for ALL breaks
        _totalBreakTime = _totalBreakTime + breakDuration;

        // Only add to extra break time if it's an extra break (for remaining hours calculation)
        if (isExtraBreak) {
          _extraBreakTime = _extraBreakTime + breakDuration;
        }

        // Reset session start time for ALL breaks (original behavior)
        _currentSessionStartTime = time;

        _breakStartTime = null;
        _currentBreakPeriodStartTime = null;
        _isOnBreak = false;

        // Track when this break ended for remaining hours calculation
        _lastBreakEndTime = time;

        // For Extra Break: unfreeze remaining hours and time logged
        if (isExtraBreak) {
          _hasFrozenRemainingHours = false;
          _hasFrozenTimeLogged = false;
          _isExtraBreak = false;
        }

        // Clear break type name
        _currentBreakTypeName = null;

        // Update total break display after adding break duration
        _updateTotalBreakDisplay();
      });
    } else {
      setState(() {
        _currentSessionStartTime = time;
        _breakStartTime = null;
        _currentBreakPeriodStartTime = null;
        _isOnBreak = false;
        _currentBreakTypeName = null;
        _isExtraBreak = false;
        _updateTotalBreakDisplay();
      });
    }
  }

  // Check if break type is Extra Break
  bool _isExtraBreakType(String breakTypeName) {
    return breakTypeName.toLowerCase().contains('extra') ||
        breakTypeName.toLowerCase().contains('extended');
  }

  // Check if break type is lunch break
  bool _isLunchBreak(String breakTypeName) {
    return breakTypeName.toLowerCase().contains('lunch');
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  bool _canNavigateToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final currentMonthStart = DateTime(now.year, now.month, 1);

    // Only allow navigation if next month is not in the future
    return nextMonth.isBefore(currentMonthStart) ||
        nextMonth.isAtSameMomentAs(currentMonthStart);
  }

  void _nextMonth() {
    if (_canNavigateToNextMonth()) {
      setState(() {
        _currentMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + 1,
          1,
        );
      });
    }
  }

  String _getMonthYearString() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  /// Extracts day number from date string
  /// Handles formats like "YYYY-MM-DD", "YYYY/MM/DD", etc.
  int? _extractDayFromDate(String dateString) {
    try {
      // Handle different date formats: "YYYY-MM-DD", "YYYY/MM/DD", etc.
      final parts = dateString.split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        return int.tryParse(parts[2]); // Day is typically the third part
      }
      // Try parsing as DateTime and extracting day
      final date = DateTime.tryParse(dateString);
      if (date != null) {
        return date.day;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Formats decimal hours to HH:MM format (e.g., 6.83 -> "6:50")
  String _formatHours(double hours) {
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    return '$wholeHours:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return FutureBuilder<DashboardAPI>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Error loading data: ${snapshot.error ?? "Unknown error"}',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          );
        }

        final apiResponse = snapshot.data!;
        final apiData = apiResponse.data;

        if (apiData == null) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: DesktopContainer(
            maxWidth: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display widgets that load their own data from API
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 1024;

                    // On desktop, arrange Daily Attendance and Time Logged side-by-side
                    if (isDesktop) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: DailyAttendanceCard(
                                onDataRefresh: _refreshDashboardData,
                                onClockIn: _setClockInTime,
                                onClockOut: _stopTimer,
                                onBreakEnd: _resetSessionAfterBreak,
                                onBreakStart: _startBreak,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: _buildTimeLoggedChart(apiData),
                            ),
                          ],
                        ),
                      );
                    }

                    // On mobile/tablet, stack vertically
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DailyAttendanceCard(
                          onDataRefresh: _refreshDashboardData,
                          onClockIn: _setClockInTime,
                          onClockOut: _stopTimer,
                          onBreakEnd: _resetSessionAfterBreak,
                          onBreakStart: _startBreak,
                        ),
                        const SizedBox(height: 20),
                        _buildTimeLoggedChart(apiData),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),
                // Monthly Report Section
                // _buildMonthlyReportSection(apiData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeLoggedChart(Data apiData) {
    // Map API data to TimeLoggedChart format
    final currentTime = _currentTime; // Use timer-based real-time
    final timeLogged = _timeLogged; // Use real-time calculated value

    // Before clock in - show default values
    if (_clockInTime == null) {
      return TimeLoggedChart(
        currentTime: currentTime,
        timeLogged: '00:00:00',
        totalBreak: '00:00:00',
        currentSession: '00:00:00',
        remainingHours: '08:00:00',
        progress: 0.0,
      );
    }

    // After clock in - calculate times
    // Total Break accumulates ALL break time with real-time updates (for display only)
    String totalBreak = _totalBreakDisplay;

    // Calculate current session
    String currentSession = '00:00:00';
    if (_isOnBreak && _currentBreakPeriodStartTime != null) {
      // Show break time when on break (any type of break)
      final breakElapsed = DateTime.now().difference(
        _currentBreakPeriodStartTime!,
      );
      currentSession = _formatElapsedTime(breakElapsed);
    } else if (_currentSessionStartTime != null && !_isOnBreak) {
      // Show work session time when not on break
      final elapsed = DateTime.now().difference(_currentSessionStartTime!);
      currentSession = _formatElapsedTime(elapsed);
    }

    // Calculate remaining hours - 8 hours target
    const double targetHours = 8.0;
    String remainingHours = '08:00:00';

    final now = DateTime.now();

    // Calculate total elapsed time since clock-in
    final elapsed = now.difference(_clockInTime!);
    final elapsedHours = elapsed.inMilliseconds / 3600000.0;

    // Get only extra break time for remaining hours calculation (professional breaks are excluded)
    final extraBreakHours = _extraBreakTime.inMilliseconds / 3600000.0;

    // FIXED: Different calculation based on break type
    if (_isOnBreak && _isExtraBreak) {
      // EXTRA BREAK: Use frozen remaining hours (stop counting)
      remainingHours = _frozenRemainingHours;
      print('🔍 EXTRA BREAK - frozen: $remainingHours');
    } else if (_isOnBreak && !_isExtraBreak) {
      // PROFESSIONAL BREAK (Meeting, Professional):
      // Continue remaining hours timer as if user is still working
      // Do NOT subtract professional break time from working hours
      final workingHours = elapsedHours - extraBreakHours;

      if (workingHours < targetHours && workingHours >= 0) {
        final remainingMs = ((targetHours - workingHours) * 3600000.0).round();
        if (remainingMs > 0) {
          final remainingDuration = Duration(milliseconds: remainingMs);
          remainingHours = _formatElapsedTime(remainingDuration);
          print(
            '🔍 PROFESSIONAL BREAK - remaining: $remainingHours (workingHours: $workingHours)',
          );
        }
      } else if (workingHours >= targetHours) {
        remainingHours = '00:00:00';
      }
    } else {
      // NOT ON BREAK: Continue counting normally
      // Only subtract extra break time from working hours (professional breaks are excluded)
      final workingHours = elapsedHours - extraBreakHours;

      if (workingHours < targetHours && workingHours >= 0) {
        final remainingMs = ((targetHours - workingHours) * 3600000.0).round();
        if (remainingMs > 0) {
          final remainingDuration = Duration(milliseconds: remainingMs);
          remainingHours = _formatElapsedTime(remainingDuration);
        }
      } else if (workingHours >= targetHours) {
        remainingHours = '00:00:00';
      } else {
        remainingHours = '08:00:00';
      }

      print('🔍 WORKING - remaining: $remainingHours');
    }

    // Calculate progress toward 8 hours based on remaining hours
    double progress = 0.0;
    if (remainingHours == '00:00:00') {
      progress = 1.0;
    } else if (remainingHours != '08:00:00') {
      // Parse remaining hours to calculate progress
      final parts = remainingHours.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        final totalSeconds = hours * 3600 + minutes * 60 + seconds;
        final targetSeconds = 8 * 3600;
        progress = 1.0 - (totalSeconds / targetSeconds);
        progress = progress.clamp(0.0, 1.0);
      }
    }

    return TimeLoggedChart(
      currentTime: currentTime,
      timeLogged: timeLogged,
      totalBreak: totalBreak,
      currentSession: currentSession,
      remainingHours: remainingHours,
      progress: progress,
    );
  }

  String _formatMinutesToDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final seconds = 0;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return '00:00:00';
    }

    try {
      // Try to parse ISO 8601 format (e.g., "2026-01-06T13:04:02+05:00")
      final dateTime = DateTime.parse(timeString);
      // Format to HH:mm:ss
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      // If parsing fails, check if it's already in HH:mm:ss format
      if (timeString.contains(':') && !timeString.contains('T')) {
        return timeString;
      }
      // Return default if format is unknown
      return '00:00:00';
    }
  }

  String _formatTime12Hour(DateTime dateTime, {bool includeSeconds = false}) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final second = dateTime.second;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    if (includeSeconds) {
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $period';
    } else {
      return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
    }
  }

  String _formatElapsedTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
