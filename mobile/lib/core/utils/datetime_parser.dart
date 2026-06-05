import 'package:intl/intl.dart';

/// Parse timestamps from API (ISO string, Firestore map, epoch ms).
DateTime? parseApiDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();

  if (value is num) {
    final raw = value.toInt();
    final ms = raw > 9999999999 ? raw : raw * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  if (value is Map) {
    final seconds = value['seconds'] ?? value['_seconds'];
    final nanos = value['nanoseconds'] ?? value['_nanoseconds'] ?? 0;
    if (seconds is num) {
      final extraMs = nanos is num ? nanos ~/ 1000000 : 0;
      final ms = seconds.toInt() * 1000 + extraMs;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
  }

  final parsed = DateTime.tryParse(value.toString().trim());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

String formatApiDateTime(DateTime dateTime, {String pattern = 'dd/MM/yyyy HH:mm'}) {
  return DateFormat(pattern).format(dateTime.toLocal());
}
