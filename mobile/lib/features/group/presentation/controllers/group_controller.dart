import 'package:flutter/foundation.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';

class GroupController extends ChangeNotifier {
  GroupController(this._repository);
  final GroupRepository _repository;

  List<GroupModel> _groups = [];
  List<GroupModel> _discoverGroups = [];
  GroupModel? _currentGroup;
  bool _isLoading = false;
  bool _isDiscoverLoading = false;
  bool _isSaving = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  List<GroupModel> get discoverGroups => _discoverGroups;
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
      final updated = await _repository.updateGroup(
        groupId,
        name: name,
        description: description,
        isPublic: isPublic,
        avatarUrl: avatarUrl,
      );
      _currentGroup = updated;
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) _groups[idx] = updated;
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
        _currentGroup = GroupModel.fromJson({
          ..._currentGroup!.toJson(),
          'members': [...(_currentGroup!.members.map((m) => m.toJson())), member.toJson()],
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

  Future<bool> leaveGroup(String groupId) async {
    try {
      await _repository.leaveGroup(groupId);
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
}
