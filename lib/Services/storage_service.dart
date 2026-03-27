import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:developer' as developer;

class StorageService {
  // Authentication keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  // Clock in/out keys
  static const String _clockInTimeKey = 'clock_in_time';
  static const String _clockInDateKey = 'clock_in_date';
  static const String _clockOutTimeKey = 'clock_out_time';
  static const String _clockOutDateKey = 'clock_out_date';

  // Historical attendance key
  static const String _historicalAttendanceKey = 'historical_attendance';

  // Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    developer.log('StorageService.getToken: retrieved token: $token');
    return token != null ? token.trim() : null;
  }

  // Set authentication token
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }

  // Save token (alias for setToken)
  static Future<void> saveToken(String token) async {
    await setToken(token);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Set user ID
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Set user name
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Set user email
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  // Save user data
  static Future<void> saveUserData({
    required String name,
    required String role,
    required int userId,
  }) async {
    await setUserId(userId.toString());
    await setUserName(name);
    await setUserRole(role);
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Set user role
  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get clock-in time
  static Future<DateTime?> getClockInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_clockInTimeKey);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Set clock-in time
  static Future<void> setClockInTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockInTimeKey, time.toIso8601String());
  }

  // Save clock-in time (alias for setClockInTime)
  static Future<void> saveClockInTime(DateTime time) async {
    await setClockInTime(time);
  }

  // Get clock-in date
  static Future<DateTime?> getClockInDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_clockInDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  // Set clock-in date
  static Future<void> setClockInDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockInDateKey, date.toIso8601String());
  }

  // Save clock-in date (alias for setClockInDate)
  static Future<void> saveClockInDate(DateTime date) async {
    await setClockInDate(date);
  }

  // Get clock-out time
  static Future<DateTime?> getClockOutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_clockOutTimeKey);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Set clock-out time
  static Future<void> setClockOutTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockOutTimeKey, time.toIso8601String());
  }

  // Save clock-out time (alias for setClockOutTime)
  static Future<void> saveClockOutTime(DateTime time) async {
    await setClockOutTime(time);
  }

  // Get clock-out date
  static Future<DateTime?> getClockOutDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_clockOutDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  // Set clock-out date
  static Future<void> setClockOutDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockOutDateKey, date.toIso8601String());
  }

  // Save clock-out date (alias for setClockOutDate)
  static Future<void> saveClockOutDate(DateTime date) async {
    await setClockOutDate(date);
  }

  // Clear clock-in time
  static Future<void> clearClockInTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clockInTimeKey);
  }

  // Clear clock-in date
  static Future<void> clearClockInDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clockInDateKey);
  }

  // Clear clock-out time
  static Future<void> clearClockOutTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clockOutTimeKey);
  }

  // Clear clock-out date
  static Future<void> clearClockOutDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clockOutDateKey);
  }

  // Save historical attendance data
  static Future<void> saveHistoricalAttendance({
    required DateTime? clockInDate,
    required DateTime? clockInTime,
    required DateTime? clockOutDate,
    required DateTime? clockOutTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'clockInDate': clockInDate?.toIso8601String(),
      'clockInTime': clockInTime?.toIso8601String(),
      'clockOutDate': clockOutDate?.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
    };
    await prefs.setString(_historicalAttendanceKey, data.toString());
  }

  // Get historical attendance data
  static Future<String?> getHistoricalAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_historicalAttendanceKey);
  }

  // Clear all stored data (for logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_clockInTimeKey);
    await prefs.remove(_clockInDateKey);
    await prefs.remove(_clockOutTimeKey);
    await prefs.remove(_clockOutDateKey);
    await prefs.remove(_historicalAttendanceKey);
  }

  // Logout (alias for clearAll)
  static Future<void> logout() async {
    await clearAll();
  }

  // Clear all preferences completely
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
