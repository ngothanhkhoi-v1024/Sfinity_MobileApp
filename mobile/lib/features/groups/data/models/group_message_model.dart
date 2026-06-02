import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, document, image, file }

class GroupMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? text;
  final MessageType type;
  final String? sharedDocumentId;
  final String? sharedDocumentTitle;
  // For image / file messages
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final Map<String, String> reactions; // userId -> emoji

  const GroupMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.text,
    required this.type,
    this.sharedDocumentId,
    this.sharedDocumentTitle,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    this.reactions = const {},
  });

  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final typeStr = data['type']?.toString() ?? 'text';
    final type = switch (typeStr) {
      'document' => MessageType.document,
      'image' => MessageType.image,
      'file' => MessageType.file,
      _ => MessageType.text,
    };

    final reactionsData = data['reactions'];
    final reactions = reactionsData is Map
        ? Map<String, String>.from(reactionsData.map((k, v) => MapEntry(k.toString(), v.toString())))
        : <String, String>{};

    return GroupMessageModel(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Ẩn danh',
      senderAvatar: data['senderAvatar']?.toString(),
      text: data['text']?.toString(),
      type: type,
      sharedDocumentId: data['sharedDocumentId']?.toString(),
      sharedDocumentTitle: data['sharedDocumentTitle']?.toString(),
      fileUrl: data['fileUrl']?.toString(),
      fileName: data['fileName']?.toString(),
      fileSize: data['fileSize'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: reactions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'type': switch (type) {
        MessageType.document => 'document',
        MessageType.image => 'image',
        MessageType.file => 'file',
        _ => 'text',
      },
      'sharedDocumentId': sharedDocumentId,
      'sharedDocumentTitle': sharedDocumentTitle,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'createdAt': FieldValue.serverTimestamp(),
      'reactions': reactions,
    };
  }
}
