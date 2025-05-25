import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageModel {
  final types.Message message;
  final bool isUser;

  ChatMessageModel({required this.message, required this.isUser});

  factory ChatMessageModel.fromUser({
    required String text,
    required String userId,
    required String userName,
  }) {
    return ChatMessageModel(
      message: types.TextMessage(
        author: types.User(id: userId, firstName: userName),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      isUser: true,
    );
  }

  factory ChatMessageModel.fromBot({
    required String text,
    required String botId,
    required String botName,
  }) {
    return ChatMessageModel(
      message: types.TextMessage(
        author: types.User(id: botId, firstName: botName),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      isUser: false,
    );
  }

  Map<String, dynamic> toMap() {
    final msg = message as types.TextMessage;
    return {
      'id': msg.id,
      'text': msg.text,
      'createdAt': msg.createdAt,
      'isUser': isUser,
      'authorId': msg.author.id,
      'authorName': msg.author.firstName,
    };
  }

  static ChatMessageModel fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      message: types.TextMessage(
        id: map['id'] ?? '',
        text: map['text'] ?? '',
        createdAt: map['createdAt'],
        author: types.User(
          id: map['authorId'] ?? '',
          firstName: map['authorName'] ?? '',
        ),
      ),
      isUser: map['isUser'] ?? false,
    );
  }

  static List<Map<String, dynamic>> toMapList(List<ChatMessageModel> messages) {
    return messages.map((m) => m.toMap()).toList();
  }

  static List<ChatMessageModel> fromMapList(List<dynamic> maps) {
    return maps
        .map((m) => ChatMessageModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }
}
