import 'package:flutter/foundation.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';

class GroupController extends ChangeNotifier {
  GroupController(this._repository);
  final GroupRepository _repository;

  List<GroupModel> _groups = [];
  List<GroupModel> _discoverGroups = [];
  List<dynamic> _receivedInvitations = [];
  List<dynamic> _groupInvitations = [];
  GroupModel? _currentGroup;
  bool _isLoading = false;
  bool _isDiscoverLoading = false;
  bool _isSaving = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  List<GroupModel> get discoverGroups => _discoverGroups;
  List<dynamic> get receivedInvitations => _receivedInvitations;
  List<dynamic> get groupInvitations => _groupInvitations;
  GroupModel? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  bool get isDiscoverLoading => _isDiscoverLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> loadMyGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _repository.getMyGroups();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GroupModel?> loadGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentGroup = await _repository.getGroup(groupId);
      return _currentGroup;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GroupModel?> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final group = await _repository.createGroup(
        name: name,
        description: description,
        isPublic: isPublic,
      );
      _groups.insert(0, group);
      notifyListeners();
      return group;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateGroup(
    String groupId, {
    String? name,
    String? description,
    bool? isPublic,
    String? avatarUrl,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final existingMembersJson = _currentGroup?.members.map((m) => m.toJson()).toList();
      final existingRole = _currentGroup?.myRole;
      final existingCount = _currentGroup?.memberCount;

      final updated = await _repository.updateGroup(
        groupId,
        name: name,
        description: description,
        isPublic: isPublic,
        avatarUrl: avatarUrl,
      );

      if (updated.members.isEmpty && existingMembersJson != null) {
        _currentGroup = GroupModel.fromJson({
          ...updated.toJson(),
          'members': existingMembersJson,
          '_count': {'members': existingCount ?? existingMembersJson.length},
          if (updated.myRole == null && existingRole != null) 'myRole': existingRole,
        });
      } else {
        _currentGroup = updated;
      }

      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) _groups[idx] = _currentGroup!;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> addMember(String groupId, String userId) async {
    try {
      final member = await _repository.addMember(groupId, userId);
      if (_currentGroup?.id == groupId) {
        final newMembers = [...(_currentGroup!.members.map((m) => m.toJson())), member.toJson()];
        _currentGroup = GroupModel.fromJson({
          ..._currentGroup!.toJson(),
          'members': newMembers,
          '_count': {'members': newMembers.length},
        });
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      await _repository.removeMember(groupId, userId);
      if (_currentGroup?.id == groupId) {
        await loadGroup(groupId);
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId, {String? newOwnerId}) async {
    try {
      await _repository.leaveGroup(groupId, newOwnerId: newOwnerId);
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      await _repository.deleteGroup(groupId);
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDiscoverGroups() async {
    _isDiscoverLoading = true;
    _error = null;
    notifyListeners();
    try {
      _discoverGroups = await _repository.discoverPublicGroups();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isDiscoverLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroup(String groupId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.joinGroup(groupId);
      _discoverGroups.removeWhere((g) => g.id == groupId);
      await loadMyGroups();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadReceivedInvitations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _receivedInvitations = await _repository.getReceivedInvitations();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupInvitations(String groupId) async {
    _error = null;
    try {
      _groupInvitations = await _repository.getGroupInvitations(groupId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<bool> inviteMember(String groupId, String userId) async {
    _error = null;
    try {
      await _repository.inviteMember(groupId, userId);
      await loadGroupInvitations(groupId);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondToInvitation(String inviteId, bool accept) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.respondToInvitation(inviteId, accept);
      _receivedInvitations.removeWhere((inv) => inv['id'] == inviteId);
      if (accept) {
        await loadMyGroups();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
