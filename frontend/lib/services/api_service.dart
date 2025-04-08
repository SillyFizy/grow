import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/storage.dart';
import '../config/app_config.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? errorMessage;

  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class ApiService {
  // Base URL for the API from configuration
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Authentication endpoints
  static const String _loginEndpoint = '/auth/login/';
  static const String _registerEndpoint = '/auth/register/';
  static const String _tokenRefreshEndpoint = '/auth/token/refresh/';

  // Headers
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  static Map<String, String> get _authHeaders {
    final token = Storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Login user
  static Future<ApiResponse> login(String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: _headers,
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save tokens
        await Storage.saveTokens(data['access'], data['refresh']);

        return ApiResponse(
          success: true,
          data: data,
        );
      } else {
        final data = jsonDecode(response.body);
        String errorMsg = data['error'] ?? 'Login failed';

        return ApiResponse(
          success: false,
          errorMessage: errorMsg,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Register user
  static Future<ApiResponse> register(
    String username,
    String email,
    String password,
    String password2,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_registerEndpoint'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Save tokens
        await Storage.saveTokens(data['access'], data['refresh']);

        return ApiResponse(
          success: true,
          data: data,
        );
      } else {
        final data = jsonDecode(response.body);
        String errorMsg = 'Registration failed';

        // Extract error messages
        if (data is Map) {
          if (data.containsKey('username')) {
            errorMsg = 'Username: ${data['username'][0]}';
          } else if (data.containsKey('email')) {
            errorMsg = 'Email: ${data['email'][0]}';
          } else if (data.containsKey('password')) {
            errorMsg = 'Password: ${data['password'][0]}';
          }
        }

        return ApiResponse(
          success: false,
          errorMessage: errorMsg,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Refresh token
  static Future<ApiResponse> refreshToken() async {
    final refreshToken = Storage.getRefreshToken();

    if (refreshToken == null) {
      return ApiResponse(
        success: false,
        errorMessage: 'No refresh token available',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_tokenRefreshEndpoint'),
        headers: _headers,
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save new access token
        await Storage.saveAccessToken(data['access']);

        return ApiResponse(
          success: true,
          data: data,
        );
      } else {
        return ApiResponse(
          success: false,
          errorMessage: 'Failed to refresh token',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Generic GET request with authentication
  static Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Generic POST request with authentication
  static Future<ApiResponse> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _authHeaders,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Generic PUT request with authentication
  static Future<ApiResponse> put(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _authHeaders,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Generic DELETE request with authentication
  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Helper method to handle responses
  static ApiResponse _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Try to decode JSON, handle potential errors
      try {
        final data =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return ApiResponse(
          success: true,
          data: data,
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          errorMessage: 'Invalid server response format',
        );
      }
    } else if (response.statusCode == 401) {
      // Handle authentication error
      return ApiResponse(
        success: false,
        errorMessage: 'Authentication failed',
      );
    } else {
      String errorMsg = 'Request failed with status: ${response.statusCode}';

      // Try to parse JSON error response, but handle non-JSON responses too
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('error')) {
            errorMsg = data['error'];
          }
        } catch (e) {
          // If it's not JSON, it's likely an HTML error page from Django
          if (response.body.contains('<!DOCTYPE') ||
              response.body.contains('<html>')) {
            errorMsg =
                'Server error (HTML response). Status code: ${response.statusCode}';
          }
        }
      }

      return ApiResponse(
        success: false,
        errorMessage: errorMsg,
      );
    }
  }
}
