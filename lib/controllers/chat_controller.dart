import 'package:get/get.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../models/chat_message_model.dart';
import '../services/azure_openai_service.dart';
import 'dart:developer' as developer;

class ChatController extends GetxController {
  final AzureOpenAIService _openAIService = Get.find<AzureOpenAIService>();
  
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isLoading = false.obs;

  static const String userId = '1';
  static const String botId = '2';
  static const String userName = 'User';
  static const String botName = 'AI Assistant';

  void _logMessage(String role, String message) {
    developer.log(
      message,
      name: 'Chat/$role',
      time: DateTime.now(),
    );
  }

  void clearChat() {
    messages.clear();
    _openAIService.conversationHistory.clear();
    // Re-add system message and welcome message
    _openAIService.conversationHistory.add({
      'role': 'system',
      'content': 'You are a helpful AI assistant. Respond in a friendly and concise manner.'
    });
    final welcomeMessage = ChatMessageModel.fromBot(
      text: 'Hello! How can I help you today?',
      botId: botId,
      botName: botName,
    );
    messages.insert(0, welcomeMessage);
    _logMessage('System', 'Chat cleared and reinitialized');
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      // Log and add user message
      _logMessage('User', text);
      final userMessage = ChatMessageModel.fromUser(
        text: text,
        userId: userId,
        userName: userName,
      );
      messages.insert(0, userMessage);

      // Set loading state
      isLoading.value = true;

      // Get bot response
      final response = await _openAIService.getChatCompletion(text);
      
      // Log and add bot message
      _logMessage('Assistant', response);
      final botMessage = ChatMessageModel.fromBot(
        text: response,
        botId: botId,
        botName: botName,
      );
      messages.insert(0, botMessage);
    } catch (e) {
      developer.log(
        'Error in sendMessage: $e',
        name: 'Chat/Error',
        error: e,
      );
      // Add error message
      final errorMessage = ChatMessageModel.fromBot(
        text: 'Sorry, I encountered an error. Please try again.',
        botId: botId,
        botName: botName,
      );
      messages.insert(0, errorMessage);
      Get.snackbar(
        'Error',
        'Failed to get response from AI',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
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
  }

  @override
  void onClose() {
    developer.log('Closing chat controller', name: 'Chat/Close');
    messages.clear();
    super.onClose();
  }
} 