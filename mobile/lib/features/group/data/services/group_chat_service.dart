import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_message_model.dart';

class GroupChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String groupId) =>
      _db.collection('groups').doc(groupId).collection('messages');

  /// Stream tin nhắn realtime của nhóm (50 tin gần nhất)
  Stream<List<GroupMessageModel>> messagesStream(String groupId) {
    return _messages(groupId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroupMessageModel.fromFirestore(doc))
            .toList());
  }

  /// Gửi tin nhắn văn bản
  Future<void> sendTextMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String text,
  }) async {
    final msg = GroupMessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      text: text,
      type: MessageType.text,
      createdAt: DateTime.now(),
    );
    await _messages(groupId).add(msg.toFirestore());
  }

  /// Chia sẻ tài liệu vào nhóm
  Future<void> shareDocument({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String documentId,
    required String documentTitle,
  }) async {
    final msg = GroupMessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      text: 'Đã chia sẻ tài liệu: $documentTitle',
      type: MessageType.document,
      sharedDocumentId: documentId,
      sharedDocumentTitle: documentTitle,
      createdAt: DateTime.now(),
    );
    await _messages(groupId).add(msg.toFirestore());
  }
}
