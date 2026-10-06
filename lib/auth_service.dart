import 'dart:convert';

import 'package:http/http.dart' as http;
import 'services/api_config.dart';

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

class SeedAccount {
  const SeedAccount({
    required this.user,
    required this.password,
  });

  final AuthUser user;
  final String password;
}

const seedAccounts = [
  SeedAccount(
    user: AuthUser(
      id: 'seed-student-1',
      name: 'Asha Patel',
      email: 'student@campus.test',
      role: 'student',
    ),
    password: 'student123',
  ),
  SeedAccount(
    user: AuthUser(
      id: 'seed-staff-1',
      name: 'Ravi Kumar',
      email: 'staff@campus.test',
      role: 'staff',
    ),
    password: 'staff123',
  ),
];

class AuthService {
  AuthService({http.Client? client, String? baseUrl, bool? useSeedData})
      : _client = client ?? http.Client(),
        _useSeedData = useSeedData ?? const bool.fromEnvironment(
          'USE_SEED_DATA',
          defaultValue: true,
        ),
        _baseUrl = baseUrl ?? defaultApiBaseUrl;

  final http.Client _client;
  final bool _useSeedData;
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

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      return await _send('/api/auth/login', {'email': email, 'password': password});
    } on AuthException catch (e) {
      if (_useSeedData && e.message.contains('Could not reach')) {
        return _loginWithSeedData(email: email, password: password);
      }
      rethrow;
    } catch (_) {
      if (_useSeedData) {
        return _loginWithSeedData(email: email, password: password);
      }
      rethrow;
    }
  }

  Future<AuthResult> _loginWithSeedData({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in seedAccounts) {
      if (account.user.email == normalizedEmail && account.password == password) {
        return AuthResult(token: 'seed-session-${account.user.id}', user: account.user);
      }
    }
    throw const AuthException(
      'Use one of the seeded demo account email and password combinations shown below.',
    );
  }

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
