class LimitBucket {
  const LimitBucket({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final int used;
  final int? limit;
  final int? remaining;

  bool get isUnlimited => limit == null;
  bool get canUse => isUnlimited || (remaining ?? 0) > 0;

  factory LimitBucket.fromJson(Map<String, dynamic> json) {
    return LimitBucket(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
    );
  }
}

class UserLimits {
  const UserLimits({
    required this.isVip,
    required this.documentDownloads,
    required this.placesCreated,
    required this.friends,
    required this.canCreateGroup,
  });

  final bool isVip;
  final LimitBucket documentDownloads;
  final LimitBucket placesCreated;
  final LimitBucket friends;
  final bool canCreateGroup;

  factory UserLimits.fromJson(Map<String, dynamic> json) {
    return UserLimits(
      isVip: json['isVip'] == true,
      documentDownloads: LimitBucket.fromJson(
        Map<String, dynamic>.from(json['documentDownloads'] as Map? ?? {}),
      ),
      placesCreated: LimitBucket.fromJson(
        Map<String, dynamic>.from(json['placesCreated'] as Map? ?? {}),
      ),
      friends: LimitBucket.fromJson(
        Map<String, dynamic>.from(json['friends'] as Map? ?? {}),
      ),
      canCreateGroup: json['canCreateGroup'] == true,
    );
  }

  static UserLimits freeDefaults() => UserLimits(
        isVip: false,
        documentDownloads: const LimitBucket(used: 0, limit: 10, remaining: 10),
        placesCreated: const LimitBucket(used: 0, limit: 10, remaining: 10),
        friends: const LimitBucket(used: 0, limit: 10, remaining: 10),
        canCreateGroup: false,
      );
}
