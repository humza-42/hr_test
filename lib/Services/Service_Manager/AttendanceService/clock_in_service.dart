import 'dart:convert';

import 'package:hr_system_test/Config/app_environment.dart';
import 'package:hr_system_test/Models/attendance_mark_api_model.dart';
import 'package:hr_system_test/Services/storage_service.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => AppEnvironment.baseUrl;

  static const String attendanceMarkEndpoint = '/employee/attendance/mark';
  static Future<ClockInAPI> clockIn() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required: No token found');
      }

      // Get user ID
      final userId = await StorageService.getUserId();
      if (userId == null) {
        throw Exception('Authentication required: User ID not found');
      }

      final url = Uri.parse('$baseUrl$attendanceMarkEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'api_token': token,
          'action': 'clock_in',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final clockInResponse = ClockInAPI.fromJson(responseData);

        if (clockInResponse.ok == true) {
          return clockInResponse;
        } else {
          throw Exception(
            clockInResponse.message ?? 'Failed to clock in: Invalid response',
          );
        }
      } else {
        Map<String, dynamic>? errorData;
        try {
          errorData = response.body.isNotEmpty
              ? jsonDecode(response.body)
              : null;
        } catch (e) {
          // If response body is not JSON, use status code message
          errorData = null;
        }

        final errorMessage =
            errorData?['message'] ??
            'Failed to clock in: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on http.ClientException {
      throw Exception('Network error: Please check your internet connection');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
