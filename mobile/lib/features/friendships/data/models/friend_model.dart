class FriendModel {
  final String friendshipId;
  final FriendUser user;
  final DateTime? since;
  final String? friendshipStatus;

  const FriendModel({
    required this.friendshipId,
    required this.user,
    this.since,
    this.friendshipStatus,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      friendshipId: json['friendshipId']?.toString() ?? json['id']?.toString() ?? '',
      user: FriendUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      since: json['since'] != null ? DateTime.tryParse(json['since'].toString()) : null,
      friendshipStatus: json['friendshipStatus']?.toString(),
    );
  }
}

class FriendUser {
  final String id;
  final String name;
  final String? avatar;
  final String? email;
  final String? friendshipStatus;
  final String? friendshipId;

  const FriendUser({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.friendshipStatus,
    this.friendshipId,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      email: json['email']?.toString(),
      friendshipStatus: json['friendshipStatus']?.toString(),
      friendshipId: json['friendshipId']?.toString(),
    );
  }
}

class PendingRequest {
  final String id;
  final FriendUser requester;
  final DateTime createdAt;

  const PendingRequest({
    required this.id,
    required this.requester,
    required this.createdAt,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      id: json['id']?.toString() ?? '',
      requester: FriendUser.fromJson(json['requester'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SentRequest {
  final String id;
  final FriendUser addressee;
  final DateTime createdAt;

  const SentRequest({
    required this.id,
    required this.addressee,
    required this.createdAt,
  });

  factory SentRequest.fromJson(Map<String, dynamic> json) {
    return SentRequest(
      id: json['id']?.toString() ?? '',
      addressee: FriendUser.fromJson(json['addressee'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
