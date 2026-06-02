import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Stream danh sách tài liệu được chia sẻ trong nhóm
  Stream<List<GroupMessageModel>> sharedDocumentsStream(String groupId) {
    return _messages(groupId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroupMessageModel.fromFirestore(doc))
            .where((msg) => msg.type == MessageType.document)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
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

  /// Chia sẻ tài liệu học tập (từ Sfinity) vào nhóm
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

  /// Upload một file lên Firebase Storage và trả về download URL
  Future<String> _uploadFile({
    required File file,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  /// Gửi ảnh vào nhóm (upload lên Firebase Storage rồi lưu URL)
  Future<void> sendImageMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required File imageFile,
    required String fileName,
    String caption = '',
    void Function(double progress)? onProgress,
  }) async {
    final downloadUrl = await _uploadFile(
      file: imageFile,
      folder: 'group_chat/$groupId/images',
      fileName: fileName,
      onProgress: onProgress,
    );

    final msg = GroupMessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.image,
      fileUrl: downloadUrl,
      fileName: fileName,
      createdAt: DateTime.now(),
      text: caption.isNotEmpty ? caption : null,
    );
    await _messages(groupId).add(msg.toFirestore());
  }

  /// Gửi file (PDF, DOCX, v.v.) vào nhóm
  Future<void> sendFileMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required File file,
    required String fileName,
    required int fileSize,
    void Function(double progress)? onProgress,
  }) async {
    final downloadUrl = await _uploadFile(
      file: file,
      folder: 'group_chat/$groupId/files',
      fileName: fileName,
      onProgress: onProgress,
    );

    final msg = GroupMessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.file,
      fileUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileSize,
      text: 'Đã gửi file: $fileName',
      createdAt: DateTime.now(),
    );
    await _messages(groupId).add(msg.toFirestore());
  }

  /// Xóa một tin nhắn khỏi cuộc trò chuyện (đánh dấu thu hồi)
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    await _messages(groupId).doc(messageId).update({
      'isDeleted': true,
      'text': 'Tin nhắn đã bị thu hồi',
    });
  }

  /// Thả icon cảm xúc cho tin nhắn
  Future<void> reactToMessage({
    required String groupId,
    required String messageId,
    required String userId,
    required String? emoji,
  }) async {
    final docRef = _messages(groupId).doc(messageId);
    if (emoji == null) {
      await docRef.update({
        'reactions.$userId': FieldValue.delete(),
      });
    } else {
      await docRef.update({
        'reactions.$userId': emoji,
      });
    }
  }
}
