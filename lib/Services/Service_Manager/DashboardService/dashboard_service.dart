import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hr_test/Config/app_environment.dart';
import 'package:hr_test/Models/dashboard_api_model.dart';
import 'package:hr_test/Services/storage_service.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => AppEnvironment.baseUrl;

  static const String dashboardEndpoint = '/employee/dashboard';
  static Future<DashboardAPI> getDashboardData() async {
    try {
      // Get authentication token
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required: No token found');
      }

      // Get user ID
      final userId = await StorageService.getUserId();
      if (userId == null) {
        throw Exception('Authentication required: User ID not found');
      }

      final url = Uri.parse('$baseUrl$dashboardEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId, 'api_token': token}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final dashboardResponse = DashboardAPI.fromJson(responseData);

        if (dashboardResponse.ok == true) {
          return dashboardResponse;
        } else {
          throw Exception('Failed to fetch dashboard data: Invalid response');
        }
      } else {
        // Handle different HTTP status codes
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
            'Failed to fetch dashboard data: ${response.statusCode}';
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
