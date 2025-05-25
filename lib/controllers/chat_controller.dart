import 'package:get/get.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:super_ai/common/custom_toast.dart';
import '../models/chat_message_model.dart';
import '../services/azure_openai_service.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController extends GetxController {
  final AzureOpenAIService _openAIService = Get.find<AzureOpenAIService>();

  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isLoading = false.obs;

  static const String userId = '1';
  static const String botId = '2';
  static const String userName = 'User';
  static const String botName = 'AI Assistant';

  String? _currentSessionId;

  void _logMessage(String role, String message) {
    developer.log(message, name: 'Chat/$role', time: DateTime.now());
  }

  // Preprocess message text to handle formatting before display
  String _preprocessMessageText(String text) {
    // No preprocessing needed for user input
    return text;
  }

  Future<void> _autoSaveSessionToFirestore() async {
    if (messages.isEmpty) return;
    // Messages are reversed before saving, so oldest is first
    final reversedMessages = messages.reversed.toList();
    String title = 'Session';
    // Try to use the first user message as the title
    final userMsg = reversedMessages.firstWhereOrNull(
      (m) =>
          m.isUser && (m.message as types.TextMessage).text.trim().isNotEmpty,
    );
    if (userMsg != null) {
      title = (userMsg.message as types.TextMessage).text.trim();
    } else {
      // Fallback: use the first bot message
      final botMsg = reversedMessages.firstWhereOrNull(
        (m) =>
            !m.isUser &&
            (m.message as types.TextMessage).text.trim().isNotEmpty,
      );
      if (botMsg != null) {
        title = (botMsg.message as types.TextMessage).text.trim();
      }
    }
    if (title.length > 40) title = '${title.substring(0, 40)}...';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final sessionData = {
      'title': title,
      'timestamp': DateTime.now(),
      'messages': ChatMessageModel.toMapList(reversedMessages),
      'userId': user.uid,
    };
    final collection = FirebaseFirestore.instance.collection('chat_sessions');
    if (_currentSessionId == null) {
      final doc = await collection.add(sessionData);
      _currentSessionId = doc.id;
    } else {
      await collection.doc(_currentSessionId).set(sessionData);
    }
  }

  void clearChat() {
    messages.clear();
    _openAIService.conversationHistory.clear();
    _openAIService.conversationHistory.add({
      'role': 'system',
      'content':
          'You are a helpful AI assistant. Respond in a friendly and concise manner.',
    });
    final welcomeMessage = ChatMessageModel.fromBot(
      text: 'Hello! How can I help you today?',
      botId: botId,
      botName: botName,
    );
    messages.insert(0, welcomeMessage);
    _currentSessionId = null;
    _autoSaveSessionToFirestore();
    _logMessage('System', 'Chat cleared and reinitialized');
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final processedUserText = _preprocessMessageText(text);
      _logMessage('User', processedUserText);
      final userMessage = ChatMessageModel.fromUser(
        text: processedUserText,
        userId: userId,
        userName: userName,
      );
      messages.insert(0, userMessage);
      await _autoSaveSessionToFirestore();
      isLoading.value = true;
      final response = await _openAIService.getChatCompletion(text);
      final processedResponse = _processBotResponse(response);
      _logMessage('Assistant', processedResponse);
      final botMessage = ChatMessageModel.fromBot(
        text: processedResponse,
        botId: botId,
        botName: botName,
      );
      messages.insert(0, botMessage);
      await _autoSaveSessionToFirestore();
    } catch (e) {
      developer.log('Error in sendMessage: $e', name: 'Chat/Error', error: e);
      final errorMessage = ChatMessageModel.fromBot(
        text: 'Sorry, I encountered an error. Please try again.',
        botId: botId,
        botName: botName,
      );
      messages.insert(0, errorMessage);
      await _autoSaveSessionToFirestore();
      CustomToast.showError(
        'Failed to get response from API',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Process bot response to handle markdown formatting
  String _processBotResponse(String text) {
    // We'll just keep the text as-is, the UI will handle the formatting
    return text;
  }

  List<types.Message> get messagesList =>
      messages.map((m) => m.message).toList();

  @override
  void onInit() {
    super.onInit();
    developer.log('Initializing chat controller', name: 'Chat/Init');
    // Add a welcome message
    final welcomeMessage = ChatMessageModel.fromBot(
      text: 'Hello! How can I help you today?',
      botId: botId,
      botName: botName,
    );
    messages.insert(0, welcomeMessage);
    _currentSessionId = null;
  }

  @override
  void onClose() {
    developer.log('Closing chat controller', name: 'Chat/Close');
    messages.clear();
    super.onClose();
  }

  /// Load a chat session from Firestore and replace current messages
  Future<void> loadSessionFromFirestore(
    Map<String, dynamic> sessionData,
  ) async {
    final List<dynamic> msgList = sessionData['messages'] ?? [];
    messages.value = ChatMessageModel.fromMapList(msgList).reversed.toList();
  }
}
