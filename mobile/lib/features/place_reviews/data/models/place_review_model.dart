class PlaceReviewModel {
  const PlaceReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    this.userId,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? authorName;
  final String? userId;
  final DateTime? createdAt;

  factory PlaceReviewModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return PlaceReviewModel(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.round() ?? 0,
      comment: json['comment']?.toString(),
      authorName: author?['name']?.toString(),
      userId: json['userId']?.toString() ?? author?['id']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class PlaceReviewSummary {
  const PlaceReviewSummary({
    this.avgRating,
    this.reviewCount = 0,
    this.reviews = const [],
  });

  final double? avgRating;
  final int reviewCount;
  final List<PlaceReviewModel> reviews;

  factory PlaceReviewSummary.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PlaceReviewModel.fromJson)
            .toList() ??
        [];
    return PlaceReviewSummary(
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      reviews: items,
    );
  }
}
