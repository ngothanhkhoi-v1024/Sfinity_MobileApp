import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/group_model.dart';

class GroupApiService {
  GroupApiService(this._client);
  final ApiClient _client;

  Future<List<GroupModel>> getMyGroups() async {
    try {
      final items = await _client.getList('/groups');
      return items.map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<GroupModel> getGroup(String groupId) async {
    try {
      final data = await _client.get('/groups/$groupId');
      return GroupModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
    bool autoApprove = true,
  }) async {
    try {
      final data = await _client.post('/groups', {
        'name': name,
        if (description != null) 'description': description,
        'isPublic': isPublic,
        'autoApprove': autoApprove,
      });
      return GroupModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<GroupModel> updateGroup(String groupId, {
    String? name,
    String? description,
    bool? isPublic,
    String? avatarUrl,
    bool? autoApprove,
  }) async {
    try {
      final data = await _client.patch('/groups/$groupId', {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'isPublic': isPublic,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (autoApprove != null) 'autoApprove': autoApprove,
      });
      return GroupModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _client.delete('/groups/$groupId');
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<GroupMemberModel> addMember(String groupId, String userId) async {
    try {
      final data = await _client.post('/groups/$groupId/members', {'userId': userId});
      return GroupMemberModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _client.delete('/groups/$groupId/members/$userId');
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> approveMember(String groupId, String userId) async {
    try {
      await _client.post('/groups/$groupId/members/$userId/approve', {});
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> leaveGroup(String groupId, {String? newOwnerId}) async {
    try {
      await _client.post('/groups/$groupId/leave', {
        if (newOwnerId != null) 'newOwnerId': newOwnerId,
      });
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<List<GroupModel>> discoverPublicGroups() async {
    try {
      final items = await _client.getList('/groups/discover');
      return items.map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<GroupMemberModel> joinGroup(String groupId) async {
    try {
      final data = await _client.post('/groups/$groupId/join', {});
      return GroupMemberModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> inviteMember(String groupId, String userId) async {
    try {
      await _client.post('/groups/$groupId/invite', {'userId': userId});
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<List<dynamic>> getGroupInvitations(String groupId) async {
    try {
      return await _client.getList('/groups/$groupId/invitations');
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<List<dynamic>> getReceivedInvitations() async {
    try {
      return await _client.getList('/groups/invitations/received');
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> respondToInvitation(String inviteId, bool accept) async {
    try {
      await _client.post('/groups/invitations/$inviteId/respond', {'accept': accept});
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }
}
