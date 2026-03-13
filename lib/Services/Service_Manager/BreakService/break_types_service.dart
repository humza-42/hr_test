import 'dart:convert';

import 'package:hr_test/Config/app_environment.dart';
import 'package:hr_test/Models/break_types_api_model.dart';
import 'package:hr_test/Services/storage_service.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => AppEnvironment.baseUrl;
  static const String breakTypesEndpoint = '/employee/break-types';

  static Future<BreakTypesAPI> getBreakTypes() async {
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

      final url = Uri.parse('$baseUrl$breakTypesEndpoint');

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
        final breakTypesResponse = BreakTypesAPI.fromJson(responseData);

        if (breakTypesResponse.ok == true) {
          return breakTypesResponse;
        } else {
          throw Exception('Failed to load break types: Invalid response');
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
            errorData?['error'] ??
            errorData?['message'] ??
            'Failed to load break types: ${response.statusCode}';
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
