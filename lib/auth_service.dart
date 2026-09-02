import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );

  final String id;
  final String name;
  final String email;
  final String role;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:3000',
        );

  final http.Client _client;
  final String _baseUrl;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) =>
      _send('/api/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

  Future<AuthResult> login({required String email, required String password}) =>
      _send('/api/auth/login', {'email': email, 'password': password});

  Future<AuthResult> _send(String path, Map<String, String> body) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(data['message'] as String? ?? 'Authentication failed.');
      }
      return AuthResult(
        token: data['token'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Could not reach the canteen server. Check your connection and try again.',
      );
    }
  }
}
