import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/friend_model.dart';

class FriendshipApiService {
  FriendshipApiService(this._client);
  final ApiClient _client;

  Future<List<FriendModel>> getFriends() async {
    try {
      final items = await _client.getList('/friends');
      return items.map((e) => FriendModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<List<PendingRequest>> getPendingRequests() async {
    try {
      final items = await _client.getList('/friends/pending');
      return items.map((e) => PendingRequest.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<List<SentRequest>> getSentRequests() async {
    try {
      final items = await _client.getList('/friends/sent');
      return items.map((e) => SentRequest.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<List<FriendUser>> searchUsers(String query) async {
    try {
      final items = await _client.getList('/friends/search', query: {'q': query});
      return items.map((e) => FriendUser.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> sendRequest(String addresseeId) async {
    try {
      await _client.post('/friends/request', {'addresseeId': addresseeId});
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> respondRequest(String friendshipId, bool accept) async {
    try {
      await _client.patch(
        '/friends/$friendshipId/respond',
        {'action': accept ? 'accept' : 'reject'},
      );
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }

  Future<void> unfriend(String friendshipId) async {
    try {
      await _client.delete('/friends/$friendshipId');
    } on DioException catch (e) {
      throw Exception(_client.errorMessage(e));
    }
  }
}
