import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, document }

class GroupMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? text;
  final MessageType type;
  final String? sharedDocumentId;
  final String? sharedDocumentTitle;
  final DateTime createdAt;

  const GroupMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.text,
    required this.type,
    this.sharedDocumentId,
    this.sharedDocumentTitle,
    required this.createdAt,
  });

  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessageModel(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Ẩn danh',
      senderAvatar: data['senderAvatar']?.toString(),
      text: data['text']?.toString(),
      type: data['type'] == 'document' ? MessageType.document : MessageType.text,
      sharedDocumentId: data['sharedDocumentId']?.toString(),
      sharedDocumentTitle: data['sharedDocumentTitle']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'type': type == MessageType.document ? 'document' : 'text',
      'sharedDocumentId': sharedDocumentId,
      'sharedDocumentTitle': sharedDocumentTitle,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
