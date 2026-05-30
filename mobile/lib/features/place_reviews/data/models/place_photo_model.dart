class PlacePhotoModel {
  const PlacePhotoModel({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.authorName,
  });

  final String id;
  final String imageUrl;
  final String? caption;
  final String? authorName;

  factory PlacePhotoModel.fromJson(Map<String, dynamic> json) {
    return PlacePhotoModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      caption: json['caption']?.toString(),
      authorName: (json['author'] as Map<String, dynamic>?)?['name']?.toString(),
    );
  }
}

class PlacePhotoListResult {
  const PlacePhotoListResult({
    this.photos = const [],
    this.photoCount = 0,
  });

  final List<PlacePhotoModel> photos;
  final int photoCount;

  factory PlacePhotoListResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PlacePhotoModel.fromJson)
            .toList() ??
        [];
    return PlacePhotoListResult(
      photos: items,
      photoCount: (json['photoCount'] as num?)?.toInt() ?? items.length,
    );
  }
}
