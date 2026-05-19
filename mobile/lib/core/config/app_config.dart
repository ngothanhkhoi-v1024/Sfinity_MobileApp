/// Cấu hình app — chỉnh khi có backend.
abstract final class AppConfig {
  static const String appName = 'Sfinity';

  /// Base URL API (backend/)
  static const String apiBaseUrl = 'http://localhost:3000';

  static const Duration apiTimeout = Duration(seconds: 30);
}
