import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import '../utils/storage.dart';
import '../config/app_config.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? errorMessage;
  final bool isTimeout;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
    this.isTimeout = false,
    this.statusCode,
  });
}

class ApiService {
  // Base URL for the API from configuration
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Authentication endpoints
  static const String _loginEndpoint = '/auth/login/';
  static const String _registerEndpoint = '/auth/register/';
  static const String _tokenRefreshEndpoint = '/auth/token/refresh/';

  // Plant endpoints
  static const String _plantsEndpoint = '/plants/';
  static const String _searchPlantsEndpoint = '/plants/search/';

  // API request timeout duration
  static const Duration _requestTimeout =
      Duration(seconds: 15); // Increased timeout

  // Headers
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json; charset=UTF-8',
      };

  static Map<String, String> get _authHeaders {
    final token = Storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Properly decode JSON with UTF-8 awareness
  static dynamic _decodeJson(String responseBody) {
    // Ensure we're decoding with UTF-8 encoding
    try {
      // For UTF-8 decoding safety, we use the following approach
      final Uint8List bytes = Uint8List.fromList(responseBody.codeUnits);
      final String decodedString = utf8.decode(bytes, allowMalformed: true);
      return json.decode(decodedString);
    } catch (e) {
      print('JSON decoding error: $e');
      // Fall back to standard decoding if the above fails
      return json.decode(responseBody);
    }
  }

  // Debug function to log connection issues
  static void _logConnectionAttempt(String url,
      {String method = 'GET', Map<String, dynamic>? data}) {
    print('========== API CONNECTION DEBUG ==========');
    print('Attempting $method request to: $url');
    print('Base URL configuration: $_baseUrl');
    print('Running as desktop exe: ${AppConfig.isDesktopExe}');
    print('Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');

    if (data != null) {
      print('Request data: $data');
    }

    print('Connection help: ${AppConfig.connectionHelp}');
    print('=========================================');
  }

  // Login user
  static Future<ApiResponse> login(String login, String password) async {
    final url = '$_baseUrl$_loginEndpoint';
    _logConnectionAttempt(url,
        method: 'POST', data: {'login': login, 'password': '***'});

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'login': login,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = _decodeJson(response.body);

        // Save tokens
        await Storage.saveTokens(data['access'], data['refresh']);

        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          errorMessage: 'Incorrect username or password',
          statusCode: response.statusCode,
        );
      } else {
        final data = _decodeJson(response.body);
        String errorMsg = data['error'] ?? 'Login failed';

        return ApiResponse(
          success: false,
          errorMessage: errorMsg,
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      print('Connection timed out for login request');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for login request: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } on http.ClientException catch (e) {
      print('HTTP client exception for login request: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Connection error: ${e.message}. The server might be unreachable.',
        isTimeout: true,
      );
    } catch (e) {
      print('Unexpected error during login request: $e');
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
    final url = '$_baseUrl$_registerEndpoint';
    _logConnectionAttempt(url,
        method: 'POST',
        data: {'username': username, 'email': email, 'password': '***'});

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'password2': password2,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 201) {
        final data = _decodeJson(response.body);

        // Save tokens
        await Storage.saveTokens(data['access'], data['refresh']);

        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        final data = _decodeJson(response.body);
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
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      print('Connection timed out for register request');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for register request: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } on http.ClientException catch (e) {
      print('HTTP client exception for register request: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Connection error: ${e.message}. The server might be unreachable.',
        isTimeout: true,
      );
    } catch (e) {
      print('Unexpected error during register request: $e');
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

    final url = '$_baseUrl$_tokenRefreshEndpoint';
    _logConnectionAttempt(url, method: 'POST');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'refresh': refreshToken,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = _decodeJson(response.body);

        // Save new access token
        await Storage.saveAccessToken(data['access']);

        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          errorMessage: 'Failed to refresh token',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      print('Connection timed out for token refresh request');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for token refresh request: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } catch (e) {
      print('Unexpected error during token refresh: $e');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Fetch all plants
  static Future<ApiResponse> fetchPlants() async {
    return get(_plantsEndpoint);
  }

  // Fetch plants by classification
  static Future<ApiResponse> fetchPlantsByClassification(
      String classification) async {
    final encodedClassification = Uri.encodeComponent(classification);
    return get('$_plantsEndpoint?classification=$encodedClassification');
  }

  // Search plants
  static Future<ApiResponse> searchPlants(String query) async {
    if (query.isEmpty) {
      return ApiResponse(
        success: false,
        errorMessage: 'Search query cannot be empty',
      );
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl$_searchPlantsEndpoint?q=$encodedQuery';

      print('Searching plants with query: $query');
      print('Search URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: _authHeaders,
          )
          .timeout(_requestTimeout);

      // Debug the raw response
      print('Search response status: ${response.statusCode}');
      print('Search response type: ${response.headers['content-type']}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          if (response.body.isEmpty) {
            return ApiResponse(
              success: true,
              data: [], // Empty list for empty response
            );
          }

          final data = _decodeJson(response.body);

          // Log the structure of the response data for debugging
          print('Response data type: ${data.runtimeType}');
          if (data is Map) {
            print('Response data keys: ${data.keys.join(', ')}');
          }

          return ApiResponse(
            success: true,
            data: data,
          );
        } catch (e) {
          print('Error decoding search response: $e');
          print(
              'Raw response (first 100 chars): ${response.body.substring(0, min(100, response.body.length))}...');

          return ApiResponse(
            success: false,
            errorMessage: 'Invalid response format: $e',
          );
        }
      } else {
        String errorMsg = 'Search failed with status: ${response.statusCode}';

        // Try to parse error message
        if (response.body.isNotEmpty) {
          try {
            final data = _decodeJson(response.body);
            if (data is Map && data.containsKey('error')) {
              errorMsg = data['error'];
            }
          } catch (_) {
            // Ignore parsing errors for error responses
          }
        }

        return ApiResponse(
          success: false,
          errorMessage: errorMsg,
        );
      }
    } on TimeoutException {
      return ApiResponse(
        success: false,
        errorMessage: 'Search timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: 'Network error. Please check your connection.',
        isTimeout: true,
      );
    } catch (e) {
      print('Exception in searchPlants: $e');
      return ApiResponse(
        success: false,
        errorMessage: 'Search error: $e',
      );
    }
  }

  // Generic GET request with authentication
  static Future<ApiResponse> get(String endpoint) async {
    try {
      // Try to get the full URL if endpoint already contains base URL
      final url = endpoint.startsWith('http') ? endpoint : '$_baseUrl$endpoint';
      _logConnectionAttempt(url);

      final response = await http
          .get(
            Uri.parse(url),
            headers: _authHeaders,
          )
          .timeout(_requestTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      print('Connection timed out for GET request to $endpoint');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for GET request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } on http.ClientException catch (e) {
      print('HTTP client exception for GET request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Connection error: ${e.message}. The server might be unreachable.',
        isTimeout: true,
      );
    } catch (e) {
      print('Unexpected error during GET request to $endpoint: $e');
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
      final url = '$_baseUrl$endpoint';
      _logConnectionAttempt(url, method: 'POST', data: data);

      final headers = _authHeaders;
      final body = jsonEncode(data);

      // Debug logging
      print('------------ POST REQUEST DEBUG ------------');
      print('URL: $url');
      print('Headers: $headers');
      print('Raw body: $data');
      print('Serialized body: $body');
      print('------------------------------------------');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(_requestTimeout);

      // Debug logging for response
      print('------------ POST RESPONSE DEBUG ------------');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('-------------------------------------------');

      return _handleResponse(response);
    } on TimeoutException {
      print('Connection timed out for POST request to $endpoint');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for POST request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } on http.ClientException catch (e) {
      print('HTTP client exception for POST request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Connection error: ${e.message}. The server might be unreachable.',
        isTimeout: true,
      );
    } catch (e) {
      print('Exception in post request to $endpoint: $e');
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
      final url = '$_baseUrl$endpoint';
      _logConnectionAttempt(url, method: 'PUT', data: data);

      final response = await http
          .put(
            Uri.parse(url),
            headers: _authHeaders,
            body: jsonEncode(data),
          )
          .timeout(_requestTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      print('Connection timed out for PUT request to $endpoint');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for PUT request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } catch (e) {
      print('Unexpected error during PUT request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Generic DELETE request with authentication
  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final url = '$_baseUrl$endpoint';
      _logConnectionAttempt(url, method: 'DELETE');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: _authHeaders,
          )
          .timeout(_requestTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      print('Connection timed out for DELETE request to $endpoint');
      return ApiResponse(
        success: false,
        errorMessage: 'Connection timed out. Please try again later.',
        isTimeout: true,
      );
    } on SocketException catch (e) {
      print('Socket exception for DELETE request to $endpoint: $e');
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to server. Please check your connection or firewall settings.',
        isTimeout: true,
      );
    } catch (e) {
      print('Unexpected error during DELETE request to $endpoint: $e');
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
            response.body.isNotEmpty ? _decodeJson(response.body) : null;

        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } catch (e) {
        print('Response decoding error: $e');
        print(
            'Raw response: ${response.body.substring(0, min(100, response.body.length))}...');

        return ApiResponse(
          success: false,
          errorMessage: 'Invalid server response format: $e',
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode == 401) {
      // Handle authentication error
      return ApiResponse(
        success: false,
        errorMessage: 'Authentication failed',
        statusCode: response.statusCode,
      );
    } else {
      String errorMsg = 'Request failed with status: ${response.statusCode}';

      // Try to parse JSON error response, but handle non-JSON responses too
      if (response.body.isNotEmpty) {
        try {
          final data = _decodeJson(response.body);
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
        statusCode: response.statusCode,
      );
    }
  }

  // Helper function to get min of two values
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
