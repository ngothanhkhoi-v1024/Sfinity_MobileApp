import '../../../friendships/data/models/friend_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final bool isPublic;
  final String creatorId;
  final DateTime createdAt;
  final List<GroupMemberModel> members;
  final int memberCount;
  final String? myRole;
  final bool autoApprove;
  final String? myStatus;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.isPublic,
    required this.creatorId,
    required this.createdAt,
    required this.members,
    required this.memberCount,
    this.myRole,
    required this.autoApprove,
    this.myStatus,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final membersList = (json['members'] as List<dynamic>? ?? [])
        .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return GroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isPublic: json['isPublic'] == true,
      creatorId: json['creatorId']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      members: membersList,
      memberCount: (json['_count'] as Map<String, dynamic>?)?['members'] as int? ?? membersList.length,
      myRole: json['myRole']?.toString(),
      autoApprove: json['autoApprove'] == null ? true : (json['autoApprove'] == true),
      myStatus: json['myStatus']?.toString(),
    );
  }

  bool get isOwner => myRole == 'OWNER';
  bool get isAdmin => myRole == 'OWNER' || myRole == 'ADMIN';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'isPublic': isPublic,
        'creatorId': creatorId,
        'createdAt': createdAt.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        '_count': {'members': memberCount},
        'myRole': myRole,
        'autoApprove': autoApprove,
        'myStatus': myStatus,
      };
}

class GroupMemberModel {
  final String id;
  final String role;
  final DateTime joinedAt;
  final FriendUser user;
  final String status;

  const GroupMemberModel({
    required this.id,
    required this.role,
    required this.joinedAt,
    required this.user,
    required this.status,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'MEMBER',
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      user: FriendUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      status: json['status']?.toString() ?? 'APPROVED',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
        'user': {'id': user.id, 'name': user.name, 'avatar': user.avatar, 'email': user.email},
        'status': status,
      };
}
