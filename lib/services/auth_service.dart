import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

/// Talks to the Sheets-based auth Apps Script, and keeps the session
/// token in secure storage so the student stays logged in until they
/// explicitly tap "log out". No auto-expiry is implemented on purpose.
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'session_token';
  static const _welcomeShownKey = 'welcome_shown';

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> hasSeenWelcome() async {
    final v = await _storage.read(key: _welcomeShownKey);
    return v == 'true';
  }

  Future<void> markWelcomeSeen() =>
      _storage.write(key: _welcomeShownKey, value: 'true');

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    Map<String, String>? location,
  }) async {
    return _post({
      'action': 'signup',
      'name': name,
      'email': email,
      'password': password,
      if (location != null) ...{
        'location_city': location['city'] ?? '',
        'location_region': location['region'] ?? '',
        'location_country': location['country'] ?? '',
        'location_ip': location['ip'] ?? '',
      },
    });
  }

  /// Student forgot their password. Backend generates a fresh
  /// temporary password and emails it to them, so they can log in and
  /// change it. Doesn't return a token — this is not a login.
  Future<AuthResult> forgotPassword({required String email}) async {
    return _post({
      'action': 'forgot_password',
      'email': email,
    });
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _post({
      'action': 'login',
      'email': email,
      'password': password,
    });

    if (result.success && result.token != null) {
      await _storage.write(key: _tokenKey, value: result.token);
    }
    return result;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    // Deliberately not clearing _welcomeShownKey — welcome note is
    // one-time per install, not per session.
  }

  // A realistic browser User-Agent + Accept header. Google's frontend
  // applies stricter bot/abuse checks to POST requests than GET ones
  // (especially ones carrying an email/password payload), and the
  // Dart http package's default headers look enough like a bot to get
  // blocked with a verification/challenge page instead of reaching the
  // Apps Script code at all. Sending headers that look like a normal
  // mobile browser avoids that wall.
  static const Map<String, String> _browserLikeHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  static const _timeout = Duration(seconds: 15);

  Future<AuthResult> _post(Map<String, String> body) async {
    try {
      var response = await http
          .post(
            Uri.parse(AppConfig.authApiUrl),
            headers: _browserLikeHeaders,
            body: body,
          )
          .timeout(_timeout);

      // Apps Script web apps commonly reply with a 302 redirect to a
      // script.googleusercontent.com URL that holds the actual JSON
      // output. Follow it manually — some Android network stacks
      // don't auto-follow redirects here.
      if ((response.statusCode == 302 || response.statusCode == 301) &&
          response.headers['location'] != null) {
        response = await http
            .get(
              Uri.parse(response.headers['location']!),
              headers: _browserLikeHeaders,
            )
            .timeout(_timeout);
      }

      final raw = response.body.trim();

      if (raw.isEmpty) {
        return AuthResult(
          success: false,
          message:
              'Empty response from server (HTTP ${response.statusCode}). '
              'Check the Apps Script deployment settings.',
        );
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Not JSON — show a snippet so we can see what actually came back
        // (e.g. an HTML error/login page instead of our script's output).
        final snippet = raw.length > 150 ? raw.substring(0, 150) : raw;
        return AuthResult(
          success: false,
          message: 'Unexpected response (HTTP ${response.statusCode}): $snippet',
        );
      }

      return AuthResult(
        success: data['success'] == true,
        message: data['message'] as String?,
        token: data['token'] as String?,
      );
    } on TimeoutException {
      return AuthResult(
        success: false,
        message: 'The connection is slow right now — please try again.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Network error: $e');
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final String? token;

  AuthResult({required this.success, this.message, this.token});
}
