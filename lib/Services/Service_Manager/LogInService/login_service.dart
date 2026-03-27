import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hr_test/Config/app_environment.dart';
import 'package:hr_test/Models/login_api_model.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => AppEnvironment.baseUrl;

  static const String loginEndpoint = '/login';
  static Future<LoginAPI> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl$loginEndpoint');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      developer.log('Login request URL: $url');
      developer.log('Login request body: {email: $email, password: ********}');
      developer.log('Login response status: ${response.statusCode}');
      developer.log('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final loginResponse = LoginAPI.fromJson(responseData);

        if (loginResponse.ok == true) {
          return loginResponse;
        } else {
          throw Exception('Login failed: Invalid credentials');
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
            errorData?['message'] ?? 'Login failed: ${response.statusCode}';
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
