import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageModel {
  final types.Message message;
  final bool isUser;

  ChatMessageModel({
    required this.message,
    required this.isUser,
  });

  factory ChatMessageModel.fromUser({
    required String text,
    required String userId,
    required String userName,
  }) {
    return ChatMessageModel(
      message: types.TextMessage(
        author: types.User(
          id: userId,
          firstName: userName,
        ),
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
        author: types.User(
          id: botId,
          firstName: botName,
        ),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      isUser: false,
    );
  }
} 