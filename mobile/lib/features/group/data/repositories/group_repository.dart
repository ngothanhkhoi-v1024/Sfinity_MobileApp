import '../models/group_model.dart';

abstract class GroupRepository {
  Future<List<GroupModel>> getMyGroups();
  Future<GroupModel> getGroup(String groupId);
  Future<GroupModel> createGroup({required String name, String? description, bool isPublic});
  Future<GroupModel> updateGroup(String groupId, {String? name, String? description, bool? isPublic, String? avatarUrl});
  Future<void> deleteGroup(String groupId);
  Future<GroupMemberModel> addMember(String groupId, String userId);
  Future<void> removeMember(String groupId, String userId);
  Future<void> leaveGroup(String groupId);
  Future<List<GroupModel>> discoverPublicGroups();
  Future<GroupMemberModel> joinGroup(String groupId);
  Future<void> inviteMember(String groupId, String userId);
  Future<List<dynamic>> getGroupInvitations(String groupId);
  Future<List<dynamic>> getReceivedInvitations();
  Future<void> respondToInvitation(String inviteId, bool accept);
}
