import 'package:flutter/foundation.dart';
import '../../data/models/friend_model.dart';
import '../../data/repositories/friendship_repository.dart';
import '../../../../app.dart';

class FriendshipController extends ChangeNotifier {
  FriendshipController(this._repository);
  final FriendshipRepository _repository;

  List<FriendModel> _friends = [];
  List<PendingRequest> _pendingRequests = [];
  List<SentRequest> _sentRequests = [];
  List<FriendUser> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<FriendModel> get friends => _friends;
  List<PendingRequest> get pendingRequests => _pendingRequests;
  List<SentRequest> get sentRequests => _sentRequests;
  List<FriendUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  int get pendingCount => _pendingRequests.length;

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _friends = await _repository.getFriends();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      _pendingRequests = await _repository.getPendingRequests();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSentRequests() async {
    try {
      _sentRequests = await _repository.getSentRequests();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      _searchResults = [];
      _error = null;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _error = null;
    notifyListeners();
    try {
      _searchResults = await _repository.searchUsers(query);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<bool> sendRequest(String addresseeId) async {
    if (!SfinityApp.userLimits.canAddFriend) {
      _error = 'FRIEND_LIMIT';
      notifyListeners();
      return false;
    }
    try {
      await _repository.sendRequest(addresseeId);
      
      // Cập nhật trạng thái trong searchResults ngay lập tức để giao diện đổi nút tức thì
      final idx = _searchResults.indexWhere((u) => u.id == addresseeId);
      if (idx != -1) {
        final oldUser = _searchResults[idx];
        _searchResults[idx] = FriendUser(
          id: oldUser.id,
          name: oldUser.name,
          avatar: oldUser.avatar,
          email: oldUser.email,
          gender: oldUser.gender,
          birthDate: oldUser.birthDate,
          address: oldUser.address,
          friendshipStatus: 'PENDING',
          friendshipId: oldUser.friendshipId,
        );
      }
      await loadSentRequests();
      await SfinityApp.userLimits.refresh();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      await SfinityApp.userLimits.refresh();
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondRequest(String friendshipId, bool accept) async {
    if (accept && !SfinityApp.userLimits.canAddFriend) {
      _error = 'FRIEND_LIMIT';
      notifyListeners();
      return false;
    }
    try {
      await _repository.respondRequest(friendshipId, accept);
      _pendingRequests.removeWhere((r) => r.id == friendshipId);
      if (accept) await loadFriends();
      await SfinityApp.userLimits.refresh();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfriend(String friendshipId) async {
    try {
      await _repository.unfriend(friendshipId);
      _friends.removeWhere((f) => f.friendshipId == friendshipId);
      _sentRequests.removeWhere((r) => r.id == friendshipId || r.addressee.id == friendshipId);
      
      // Reset trạng thái trong searchResults ngay lập tức nếu người dùng này đang ở trong danh sách tìm kiếm
      final idx = _searchResults.indexWhere((u) => u.friendshipId == friendshipId || u.id == friendshipId);
      if (idx != -1) {
        final oldUser = _searchResults[idx];
        _searchResults[idx] = FriendUser(
          id: oldUser.id,
          name: oldUser.name,
          avatar: oldUser.avatar,
          email: oldUser.email,
          gender: oldUser.gender,
          birthDate: oldUser.birthDate,
          address: oldUser.address,
          friendshipStatus: null,
          friendshipId: null,
        );
      }
      
      notifyListeners();
      await SfinityApp.userLimits.refresh();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      await SfinityApp.userLimits.refresh();
      notifyListeners();
      return false;
    }
  }
}
