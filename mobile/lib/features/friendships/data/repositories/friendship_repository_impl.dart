import '../models/friend_model.dart';
import '../services/friendship_api_service.dart';
import 'friendship_repository.dart';

class FriendshipRepositoryImpl implements FriendshipRepository {
  FriendshipRepositoryImpl(this._service);
  final FriendshipApiService _service;

  @override
  Future<List<FriendModel>> getFriends() => _service.getFriends();

  @override
  Future<List<PendingRequest>> getPendingRequests() => _service.getPendingRequests();

  @override
  Future<List<SentRequest>> getSentRequests() => _service.getSentRequests();

  @override
  Future<List<FriendUser>> searchUsers(String query) => _service.searchUsers(query);

  @override
  Future<void> sendRequest(String addresseeId) => _service.sendRequest(addresseeId);

  @override
  Future<void> respondRequest(String friendshipId, bool accept) =>
      _service.respondRequest(friendshipId, accept);

  @override
  Future<void> unfriend(String friendshipId) => _service.unfriend(friendshipId);
}
