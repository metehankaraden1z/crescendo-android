import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'api_exception.dart';
import 'session_store.dart';

/// Talks to the Crescendo server's JSON API.
///
/// The server tracks logins with an HttpOnly `cr_session` cookie. Native HTTP
/// clients don't keep cookies, so this class captures it from `Set-Cookie`,
/// stores it securely, and sends it back on every request.
class ApiService {
  ApiService({http.Client? client, SessionStore? sessionStore, String? baseUrl})
      : _client = client ?? http.Client(),
        _sessionStore = sessionStore ?? SessionStore(),
        baseUrl = baseUrl ?? Env.apiBaseUrl;

  static const _cookieName = 'cr_session';
  static const _timeout = Duration(seconds: 20);
  static final _cookiePattern = RegExp('$_cookieName=([^;]*)');

  final String baseUrl;
  final http.Client _client;
  final SessionStore _sessionStore;
  String? _token;
  bool _tokenLoaded = false;

  // --- auth ---------------------------------------------------------------

  Future<bool> get hasSession async {
    await _loadToken();
    return _token != null;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await post('/api/auth/login', {'username': username.trim(), 'password': password});
    return data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    final data = await post('/api/auth/register', {'username': username.trim(), 'password': password});
    return data['user'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await post('/api/auth/logout');
    } finally {
      await _setToken(null); // log out locally even if the server can't be reached
    }
  }

  /// The logged-in user, or null when there is no valid session.
  Future<Map<String, dynamic>?> me() async {
    final data = await get('/api/me');
    return data['user'] as Map<String, dynamic>?;
  }

  // --- generic verbs ------------------------------------------------------

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, [Object? body]) => _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  // --- internals ----------------------------------------------------------

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    await _loadToken();
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)..headers['Accept'] = 'application/json';
    if (_token != null) request.headers['Cookie'] = '$_cookieName=$_token';
    if (method != 'GET') {
      // The server only accepts JSON bodies on requests that change data.
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body ?? const <String, dynamic>{});
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(_timeout));
    } on TimeoutException {
      throw const ApiException(0, 'The server took too long to respond.');
    } on SocketException {
      throw ApiException(0, "Can't reach the Crescendo server at $baseUrl.");
    } on http.ClientException catch (e) {
      throw ApiException(0, "Can't reach the Crescendo server (${e.message}).");
    }

    await _captureSession(response);

    Map<String, dynamic> data = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } on FormatException {
        // Not JSON (e.g. a proxy error page); handled by the status check below.
      }
    }

    if (response.statusCode >= 400) {
      if (response.statusCode == 401) await _setToken(null); // session expired or revoked
      throw ApiException(
        response.statusCode,
        data['error'] as String? ?? 'Request failed (${response.statusCode}).',
      );
    }
    return data;
  }

  Future<void> _captureSession(http.Response response) async {
    final header = response.headers['set-cookie'];
    if (header == null) return;
    final match = _cookiePattern.firstMatch(header);
    if (match == null) return;
    final value = match.group(1)!;
    await _setToken(value.isEmpty ? null : value); // logout sends an empty cookie
  }

  Future<void> _loadToken() async {
    if (_tokenLoaded) return;
    _token = await _sessionStore.read();
    _tokenLoaded = true;
  }

  Future<void> _setToken(String? token) async {
    _token = token;
    _tokenLoaded = true;
    await _sessionStore.write(token);
  }
}
