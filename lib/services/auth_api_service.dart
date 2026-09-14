import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_config.dart';

class AuthApiException implements Exception {
  final String message;
  const AuthApiException(this.message);

  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  static const _tokenKey = 'fabricare_auth_token';

  String? _token;

  String? get token => _token;

  Future<void> loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
      }),
    );
    return _parseAuthResponse(response);
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _parseAuthResponse(response);
  }

  Future<User?> fetchCurrentUser() async {
    if (_token == null || _token!.isEmpty) return null;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: _headers(withAuth: true),
    );

    if (response.statusCode == 401) {
      await _saveToken(null);
      return null;
    }

    if (response.statusCode != 200) {
      throw AuthApiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: _headers(withAuth: true),
        );
      } catch (_) {}
    }
    await _saveToken(null);
  }

  Future<User> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? location,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone': phone ?? '',
        'location': location ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw AuthApiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/password'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw AuthApiException(_errorMessage(response));
    }
  }

  Future<User> _parseAuthResponse(http.Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthApiException(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthApiException('Server did not return an auth token.');
    }
    await _saveToken(token);
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }
}
