import 'package:flutter/material.dart';
import 'package:hr_test/Models/dashboard_api_model.dart';

import 'package:hr_test/Services/Service_Manager/DashboardService/dashboard_service.dart'
    as DashboardService;
import 'package:hr_test/Services/Service_Manager/AttendanceService/clock_in_service.dart'
    as ClockInService;
import 'package:hr_test/Services/Service_Manager/AttendanceService/clock_out_service.dart'
    as ClockOutService;
import 'package:hr_test/Services/Service_Manager/AttendanceService/start_break_service.dart'
    as StartBreakService;
import 'package:hr_test/Services/Service_Manager/AttendanceService/break_end_service.dart'
    as BreakEndService;
import 'package:hr_test/Services/Service_Manager/AttendanceService/extra_break_service.dart'
    as ExtraBreakService;
import 'package:hr_test/Services/storage_service.dart';
import 'package:hr_test/Widgets/Daily_attendance_card/break_type_selection_dialog.dart';
import 'package:hr_test/Widgets/Daily_attendance_card/attendance_helpers.dart';
import 'package:hr_test/Widgets/action_buttons.dart';
import 'package:hr_test/Widgets/clock_card.dart';
import 'package:hr_test/Widgets/status_badge.dart';

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
        // Try to get clock-in time from API response
        DateTime? apiClockInTime;
        if (apiData?.checkIn is String &&
            apiData?.checkIn != null &&
            apiData?.checkIn!.isNotEmpty == true) {
          try {
            final checkInString = apiData?.checkIn;
            if (checkInString != null && checkInString.isNotEmpty) {
              apiClockInTime = DateTime.parse(checkInString).toLocal();
            }
          } catch (e) {}
        }

        setState(() {
          _optimisticCheckIn = true;
          _optimisticCheckOut = false;
          // If we got a valid time from API, use it
          if (apiClockInTime != null) {
            _clockInTime = apiClockInTime;
            _clockInDate = DateTime(
              apiClockInTime.year,
              apiClockInTime.month,
              apiClockInTime.day,
            );
            // Also save to storage for consistency across app restarts
            StorageService.saveClockInTime(apiClockInTime);
            StorageService.saveClockInDate(_clockInDate!);
          }
        });
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

  void _showBreakTypeSelectionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return BreakTypeSelectionDialog(
          onBreakTypeSelected: (breakTypeId, breakTypeName) {
            _startBreakWithType(breakTypeId, breakTypeName);
          },
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
              isValidApiCheckIn = false;
            }
          } catch (e) {}
        }

        final checkIn = forceCheckIn || _optimisticCheckIn || isValidApiCheckIn;

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

        // Format clock in/out times
        // If we have stored times, use them; otherwise fall back to API state
        String clockInTime = _clockInTime != null
            ? AttendanceHelpers.formatTime12Hour(_clockInTime!)
            : (checkIn ? '--:--' : '-');
        String clockOutTime = _clockOutTime != null
            ? AttendanceHelpers.formatTime12Hour(_clockOutTime!)
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
              StatusBadge(
                checkIn: checkIn,
                optimisticOnBreak: _optimisticOnBreak,
                currentBreakTypeName: _currentBreakTypeName,
                isDark: isDark,
                textColor: textColor,
                cardColor: cardColor,
              ),
              const SizedBox(height: 20),
              // Clock In/Out Cards
              Row(
                children: [
                  Expanded(
                    child: ClockCard(
                      label: 'CLOCK IN',
                      time: clockInTime,
                      labelColor: Color.fromARGB(255, 30, 107, 185),
                      timeColor: Color.fromARGB(255, 30, 107, 185),
                      backgroundColor: const Color.fromARGB(255, 219, 234, 254),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClockCard(
                      label: 'CLOCK OUT',
                      time: clockOutTime,
                      labelColor: Color.fromARGB(255, 149, 33, 168),
                      timeColor: Color.fromARGB(255, 149, 33, 168),
                      backgroundColor: const Color(0xFFE0B2F7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30), // Increased from 20
              // Action Buttons
              ActionButtons(
                isLoadingBreak: _isLoadingBreak,
                checkIn: checkIn,
                checkOut: checkOut,
                isOnBreak: isOnBreak,
                isDark: isDark,
                textColor: textColor,
                onTakeBreakPressed: isOnBreak
                    ? _handleEndBreak
                    : _handleStartBreak,
                onClockInPressed: _handleClockIn,
                onClockOutPressed: _handleClockOut,
              ),
            ],
          ),
        );
      },
    );
  }
}
