/// Hành động gợi ý từ trợ lý (deep link trong app).
sealed class AssistantAction {
  const AssistantAction();

  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    return switch (type) {
      'open_place' => OpenPlaceAction(
          placeId: json['placeId']?.toString() ?? '',
          label: json['label']?.toString(),
        ),
      'open_document' => OpenDocumentAction(
          documentId: json['documentId']?.toString() ?? '',
          label: json['label']?.toString(),
        ),
      'open_study_near_me' => const OpenStudyNearMeAction(),
      'open_map' => OpenMapAction(
          lat: (json['lat'] as num?)?.toDouble() ?? 0,
          lng: (json['lng'] as num?)?.toDouble() ?? 0,
          label: json['label']?.toString(),
        ),
      _ => UnknownAssistantAction(type: type),
    };
  }

  String get displayLabel;
}

class OpenPlaceAction extends AssistantAction {
  const OpenPlaceAction({required this.placeId, this.label});

  final String placeId;
  final String? label;

  @override
  String get displayLabel => label ?? placeId;
}

class OpenDocumentAction extends AssistantAction {
  const OpenDocumentAction({required this.documentId, this.label});

  final String documentId;
  final String? label;

  @override
  String get displayLabel => label ?? documentId;
}

class OpenStudyNearMeAction extends AssistantAction {
  const OpenStudyNearMeAction();

  @override
  String get displayLabel => 'study_near_me';
}

class OpenMapAction extends AssistantAction {
  const OpenMapAction({required this.lat, required this.lng, this.label});

  final double lat;
  final double lng;
  final String? label;

  @override
  String get displayLabel => label ?? '$lat,$lng';
}

class UnknownAssistantAction extends AssistantAction {
  const UnknownAssistantAction({required this.type});

  final String type;

  @override
  String get displayLabel => type;
}
