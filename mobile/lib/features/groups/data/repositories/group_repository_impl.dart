import '../models/group_model.dart';
import '../services/group_api_service.dart';
import 'group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._service);
  final GroupApiService _service;

  @override
  Future<List<GroupModel>> getMyGroups() => _service.getMyGroups();

  @override
  Future<GroupModel> getGroup(String groupId) => _service.getGroup(groupId);

  @override
  Future<GroupModel> createGroup({required String name, String? description, bool isPublic = false, bool autoApprove = true}) =>
      _service.createGroup(name: name, description: description, isPublic: isPublic, autoApprove: autoApprove);

  @override
  Future<GroupModel> updateGroup(String groupId, {String? name, String? description, bool? isPublic, String? avatarUrl, bool? autoApprove}) =>
      _service.updateGroup(groupId, name: name, description: description, isPublic: isPublic, avatarUrl: avatarUrl, autoApprove: autoApprove);

  @override
  Future<void> deleteGroup(String groupId) => _service.deleteGroup(groupId);

  @override
  Future<GroupMemberModel> addMember(String groupId, String userId) => _service.addMember(groupId, userId);

  @override
  Future<void> removeMember(String groupId, String userId) => _service.removeMember(groupId, userId);

  @override
  Future<void> approveMember(String groupId, String userId) => _service.approveMember(groupId, userId);

  @override
  Future<void> leaveGroup(String groupId, {String? newOwnerId}) => _service.leaveGroup(groupId, newOwnerId: newOwnerId);

  @override
  Future<List<GroupModel>> discoverPublicGroups() => _service.discoverPublicGroups();

  @override
  Future<GroupMemberModel> joinGroup(String groupId) => _service.joinGroup(groupId);

  @override
  Future<void> inviteMember(String groupId, String userId) => _service.inviteMember(groupId, userId);

  @override
  Future<List<dynamic>> getGroupInvitations(String groupId) => _service.getGroupInvitations(groupId);

  @override
  Future<List<dynamic>> getReceivedInvitations() => _service.getReceivedInvitations();

  @override
  Future<void> respondToInvitation(String inviteId, bool accept) => _service.respondToInvitation(inviteId, accept);
}
