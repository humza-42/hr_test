import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:hr_test/Config/app_environment.dart';
import 'package:hr_test/Models/dashboard_api_model.dart';
import 'package:hr_test/Services/storage_service.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => AppEnvironment.baseUrl;

  static const String dashboardEndpoint = '/employee/dashboard';
  static Future<DashboardAPI> getDashboardData() async {
    debugPrint('DashboardService.getDashboardData called');
    try {
      // Get authentication token
      final token = await StorageService.getToken();
      debugPrint('Retrieved token from storage: $token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required: No token found');
      }

      // Debug token format
      final segments = token.split('.');
      debugPrint('Token segments: ${segments.length} - Token: $token');

      // Validate token format: if it looks like a JWT (contains dots), it must have exactly 3 segments
      // If it doesn't contain dots, accept it as a plain token (common for many auth systems)
      if (token.contains('.') && segments.length != 3) {
        throw Exception(
          'Invalid token format: Expected a JWT with three segments, got ${segments.length}',
        );
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
        body: jsonEncode({'user_id': userId}),
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
        print('Dashboard API Error - Status: ${response.statusCode}');
        print('Dashboard API Error - Body: ${response.body}');

        Map<String, dynamic>? errorData;
        try {
          errorData = response.body.isNotEmpty
              ? jsonDecode(response.body)
              : null;
        } catch (e) {
          // If response body is not JSON, use status code message
          errorData = null;
        }

        // Log the error details for debugging
        developer.log(
          'Dashboard API Error:',
          error: response.statusCode,
          name: 'DashboardService',
        );
        if (errorData != null) {
          developer.log(
            'Error Response Body:',
            error: errorData,
            name: 'DashboardService',
          );
        } else {
          developer.log(
            'Error Response Body (non-JSON):',
            error: response.body,
            name: 'DashboardService',
          );
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
