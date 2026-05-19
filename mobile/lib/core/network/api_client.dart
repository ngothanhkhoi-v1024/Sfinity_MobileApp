import '../config/app_config.dart';

// TODO: Dio / http client — interceptors, token refresh

/// Client gọi API backend.
class ApiClient {
  ApiClient();

  final String baseUrl = AppConfig.apiBaseUrl;
}
