import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  TextSpan _buildFormattedText(String text, BuildContext context, bool isUser) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    bool isInList = false;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.isEmpty) {
        if (i < lines.length - 1) { // Only add newline if not the last line
          spans.add(const TextSpan(text: '\n'));
        }
        continue;
      }

      // Handle headings
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '${line.substring(4)}${i < lines.length - 1 ? '\n' : ''}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            height: 1.8,
          ),
        ));
      }
      // Handle bullet points
      else if (line.startsWith('- ')) {
        if (!isInList && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        isInList = true;
        spans.add(TextSpan(
          text: '• ${line.substring(2)}${i < lines.length - 1 ? '\n' : ''}',
          style: TextStyle(
            fontSize: 15,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            height: 1.4,
          ),
        ));
      }
      // Handle normal paragraphs
      else {
        isInList = false;
        spans.add(TextSpan(
          text: '$line${i < lines.length - 1 ? '\n' : ''}',
          style: TextStyle(
            fontSize: 15,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            height: 1.4,
          ),
        ));
      }
    }

    return TextSpan(children: spans);
  }

  Widget _buildMessage(String text, bool isUser, BuildContext context, bool isLight) {
    // Clean up any potential encoding issues
    final cleanText = text.replaceAll('ð', '😊')
                         .replaceAll('', '')
                         .trim();
                         
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : (isLight ? Colors.grey.shade100 : Colors.grey.shade900),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 16 : 4),
          topRight: Radius.circular(isUser ? 4 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText.rich(
        _buildFormattedText(cleanText, context, isUser),
        textAlign: TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return Scaffold(
      backgroundColor: isLight ? Colors.grey.shade50 : Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
              ),
              child: Icon(
                Icons.assistant_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Obx(() => Text(
                  controller.isLoading.value ? 'Typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.7),
                  ),
                )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              controller.clearChat();
            },
            tooltip: 'Clear Chat',
          ),
          IconButton(
            icon: Icon(
              Get.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark
              );
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: controller.isLoading.value ? 1 : 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          )),
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isUser = message.isUser;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 8, bottom: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight ? Colors.white : Colors.grey.shade800,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.assistant_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                        Flexible(
                          child: _buildMessage(
                            (message.message as types.TextMessage).text,
                            isUser,
                            context,
                            isLight,
                          ),
                        ),
                        if (isUser) const SizedBox(width: 34),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() => ChatInput(
            onSendPressed: controller.sendMessage,
            isLoading: controller.isLoading.value,
          )),
        ],
      ),
    );
  }
} 