import 'dart:io' show Platform;

abstract final class Env {
  /// Override with: flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    // The Android emulator reaches the host machine's localhost through 10.0.2.2.
    return Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  }
}
