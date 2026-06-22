import '../../../../core/network/api_client.dart';

class AssistantApiService {
  AssistantApiService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? context,
    List<Map<String, String>>? history,
    double? lat,
    double? lng,
  }) {
    return _api.post('/assistant/chat', {
      'message': message,
      if (context != null && context.isNotEmpty) 'context': context,
      if (history != null && history.isNotEmpty) 'history': history,
      if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
    });
  }
}
