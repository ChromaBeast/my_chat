import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../controllers/chat_controller.dart';
import '../controllers/text_to_speech_controller.dart';
import '../widgets/chat_input.dart';
import '../widgets/animated_dots.dart';
import 'chat_history_screen.dart';
import '../models/chat_session_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends GetView<ChatController> {
  final String? sessionTitle;
  final ChatSessionModel? session;
  const ChatScreen({super.key, this.sessionTitle, this.session});

  Widget _buildMessage(
    String text,
    bool isUser,
    BuildContext context,
    bool isLight,
  ) {
    // Clean up any potential encoding issues and remove custom bold tags for display.
    final cleanText = text
        .replaceAll('ð', '😊')
        .replaceAll('<<bold>>', '')
        .replaceAll('<</bold>>', '')
        .trim();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: MarkdownBody(
        data: cleanText,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          // Customize styles for assistant messages
          p: TextStyle(
            fontSize: 15,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            height: 1.4,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
          ),
          em: TextStyle(
            fontStyle: FontStyle.italic,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
          ),
          h1: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            height: 1.8,
          ),
          h2: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            height: 1.8,
          ),
          h3: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            height: 1.8,
          ),
          blockquote: TextStyle(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9)
                : Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            backgroundColor: isUser
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // New method to strip markdown for TTS
  String _stripMarkdown(String text) {
    String strippedText = text;

    // Remove code blocks (standard ```)
    strippedText = strippedText.replaceAll(
      RegExp(r'```.*?```', multiLine: true, dotAll: true),
      '',
    );
    // Remove headings (standard #, ##, ###)
    strippedText = strippedText.replaceAll(
      RegExp(r'^(#+\s.*)', multiLine: true),
      '',
    );
    // Remove blockquotes (standard >)
    strippedText = strippedText.replaceAll(
      RegExp(r'^>\s', multiLine: true),
      '',
    );
    // Remove list markers (standard - and 1., 2. etc.)
    strippedText = strippedText
        .split('\n')
        .map((line) {
          line = line.replaceFirst(RegExp(r'^\s*([-*+]|\d+\.)\s+'), '');
          return line;
        })
        .join('\n');

    // Remove bold (standard **)
    strippedText = strippedText.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1)!,
    );
    // Remove legacy bold (<<bold>>)
    strippedText = strippedText.replaceAllMapped(
      RegExp(r'<<bold>>(.*?)<</bold>>', caseSensitive: false),
      (match) => match.group(1)!,
    );

    // Remove italic (standard *)
    strippedText = strippedText.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => match.group(1)!,
    );

    // Replace dollar signs with 'dollar' for TTS clarity
    strippedText = strippedText.replaceAll(r'$', 'dollar');

    return strippedText.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      color: isLight ? Colors.grey.shade50 : Colors.black,
      child: Column(
        children: [
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: controller.isLoading.value ? 1 : 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isUser = message.isUser;
                  final messageText =
                      (message.message as types.TextMessage).text;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 8, bottom: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight
                                  ? Colors.white
                                  : Colors.grey.shade800,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.shadow.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo.png',
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        Flexible(
                          child: isUser
                              ? _buildMessage(
                                  messageText,
                                  isUser,
                                  context,
                                  isLight,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildMessage(
                                      messageText,
                                      isUser,
                                      context,
                                      isLight,
                                    ),
                                    const SizedBox(height: 4),
                                    Obx(() {
                                      final tts =
                                          Get.find<TextToSpeechController>();
                                      final isSpeaking =
                                          tts.isSpeaking.value &&
                                          tts.textController.text ==
                                              messageText;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.volume_up,
                                              size: 18,
                                            ),
                                            tooltip: 'Read aloud',
                                            onPressed: () {
                                              final tts =
                                                  Get.find<
                                                    TextToSpeechController
                                                  >();
                                              tts.speakWithLocale(
                                                _stripMarkdown(messageText),
                                                locale: 'en-IN',
                                              );
                                            },
                                          ),
                                          if (isSpeaking)
                                            AnimatedDots(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              size: 8,
                                            ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null && user.photoURL != null) {
                                return CircleAvatar(
                                  radius: 13,
                                  backgroundImage: NetworkImage(user.photoURL!),
                                );
                              } else {
                                return CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Obx(
            () => ChatInput(
              onSendPressed: controller.sendMessage,
              isLoading: controller.isLoading.value,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreenTabView extends StatelessWidget {
  const ChatScreenTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<ChatController>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isLight ? Colors.grey.shade50 : Colors.black,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: Image.asset('assets/logo.png', width: 32, height: 32),
              ),
              const SizedBox(width: 12),
              Text(
                'Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.refresh_outlined),
          //     onPressed: () {
          //       controller.clearChat();
          //     },
          //     tooltip: 'Clear Chat',
          //   ),
          //   IconButton(
          //     icon: Icon(
          //       Get.isDarkMode
          //
          //            ?Icons.dark_mode_outlined: Icons.light_mode_outlined
          //     ),
          //     onPressed: () {
          //       Get.changeThemeMode(
          //         Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
          //       );
          //     },
          //   ),
          // ],
        ),
        body: Column(
          children: [
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.only(top: 16),
              child: TabBar(
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 4, color: colorScheme.primary),
                  insets: const EdgeInsets.symmetric(horizontal: 32),
                ),
                labelStyle: Theme.of(context).textTheme.titleMedium,
                tabs: const [
                  Tab(icon: Icon(Icons.chat_bubble_outline)),
                  Tab(icon: Icon(Icons.history)),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [ChatScreen(), ChatHistoryScreen()]),
            ),
          ],
        ),
      ),
    );
  }
}
