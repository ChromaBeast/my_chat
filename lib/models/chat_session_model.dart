import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message_model.dart';

class ChatSessionModel {
  final String id;
  final String title;
  final DateTime timestamp;
  final List<ChatMessageModel> messages;
  final String userId;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
    required this.userId,
  });

  factory ChatSessionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ChatSessionModel(
      id: id ?? '',
      title: map['title'] ?? 'Session',
      timestamp:
          (map['timestamp'] is Timestamp)
              ? (map['timestamp'] as Timestamp).toDate()
              : (map['timestamp'] is DateTime)
              ? map['timestamp'] as DateTime
              : DateTime.now(),
      messages: ChatMessageModel.fromMapList(map['messages'] ?? []),
      userId: map['userId'] ?? '',
    );
  }

  factory ChatSessionModel.fromFirestore(DocumentSnapshot doc) {
    return ChatSessionModel.fromMap(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timestamp': timestamp,
      'messages': ChatMessageModel.toMapList(messages),
      'userId': userId,
    };
  }
}
