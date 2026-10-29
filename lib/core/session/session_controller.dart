import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import '../network/api_service.dart';

/// Who is logged in. The app shows the login screen or the main tabs based on this.
class SessionController extends ChangeNotifier {
  SessionController(this.api);

  final ApiService api;

  Map<String, dynamic>? _user;
  bool _restoring = true;
  String? _startupError;

  bool get isRestoring => _restoring;
  bool get isLoggedIn => _user != null;
  String? get startupError => _startupError;
  String get username => (_user?['username'] as String?) ?? '';

  /// On launch: reuse a saved session if the server still accepts it.
  Future<void> restore() async {
    _restoring = true;
    _startupError = null;
    notifyListeners();
    try {
      _user = await api.hasSession ? await api.me() : null;
    } on ApiException catch (e) {
      _user = null;
      if (e.isOffline) _startupError = e.message;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _user = await api.login(username, password);
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    _user = await api.register(username, password);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } on ApiException {
      // Already logged out locally; nothing else to do.
    }
    _user = null;
    notifyListeners();
  }
}
