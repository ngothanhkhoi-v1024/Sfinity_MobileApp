/// Cấu hình app — chỉnh khi có backend.
abstract final class AppConfig {
  static const String appName = 'Sfinity';

  /// API backend — dùng cho Chrome / web (flutter run -d chrome)
  static const String apiBaseUrl = 'http://localhost:3000/api';

  static const Duration apiTimeout = Duration(seconds: 30);
}
