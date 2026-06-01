import '../models/friend_model.dart';

abstract class FriendshipRepository {
  Future<List<FriendModel>> getFriends();
  Future<List<PendingRequest>> getPendingRequests();
  Future<List<SentRequest>> getSentRequests();
  Future<List<FriendUser>> searchUsers(String query);
  Future<void> sendRequest(String addresseeId);
  Future<void> respondRequest(String friendshipId, bool accept);
  Future<void> unfriend(String friendshipId);
}
