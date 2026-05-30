import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình app — giá trị đọc từ [assets/env/app.env] (flutter_dotenv).
///
/// Chọn URL backend theo cách run: mở file đó, bật đúng một dòng
/// `API_BASE_URL` và comment các dòng còn lại (xem chú thích trong file).
abstract final class AppConfig {
  static const String appName = 'Sfinity';

  static String get apiBaseUrl {
    const fallback = 'http://10.0.2.2:3000/api';
    // const fallback = 'http://192.168.1.19:3000/api';
    if (!dotenv.isInitialized) return fallback;
    final raw = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    return raw.replaceAll(RegExp(r'/+$'), '');
  }

  static Duration get apiTimeout {
    if (!dotenv.isInitialized) return const Duration(seconds: 30);
    final raw = dotenv.maybeGet('API_TIMEOUT_SECONDS')?.trim();
    final sec = int.tryParse(raw ?? '') ?? 30;
    return Duration(seconds: sec.clamp(1, 300));
  }
}
