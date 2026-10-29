class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  /// 0 means the request never reached the server (offline, timeout, wrong URL).
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isOffline => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
