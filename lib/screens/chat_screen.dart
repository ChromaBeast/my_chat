import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
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

  TextSpan _buildFormattedText(String text, BuildContext context, bool isUser) {
    final List<TextSpan> spans = [];

    // Process text line by line to handle both bold and italic formatting
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.contains('<<bold>>') || line.contains('*')) {
        // Current position in the string
        int position = 0;
        // Resulting text spans for this line
        List<TextSpan> lineSpans = [];

        // Process bold tags first
        if (line.contains('<<bold>>')) {
          final boldRegex = RegExp(r'<<bold>>(.*?)<<\/bold>>');
          String processedLine = line;

          for (final match in boldRegex.allMatches(line)) {
            // Add text before bold
            if (match.start > position) {
              final beforeText = line.substring(position, match.start);
              lineSpans.add(
                TextSpan(
                  text: beforeText,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                    height: 1.4,
                  ),
                ),
              );
            }

            // Add bold text
            lineSpans.add(
              TextSpan(
                text: match.group(1) ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color:
                      isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                  height: 1.4,
                ),
              ),
            );

            position = match.end;
          }

          // Add any remaining text
          if (position < line.length) {
            final afterText = line.substring(position);

            // Check for italic formatting in the remaining text
            if (afterText.contains('*')) {
              _processItalicText(afterText, lineSpans, context, isUser);
            } else {
              lineSpans.add(
                TextSpan(
                  text: afterText,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                    height: 1.4,
                  ),
                ),
              );
            }
          }
        } else if (line.contains('*')) {
          // Process italic text if no bold tags
          _processItalicText(line, lineSpans, context, isUser);
        }

        // Add all spans for this line
        spans.addAll(lineSpans);

        // Add newline if not last line
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
      } else {
        // Process regular line with original formatting logic
        _processTextLine(line, i, lines.length, spans, context, isUser);
      }
    }

    if (spans.isEmpty) {
      // Fallback to original formatting logic
      return _processOriginalFormatting(text, context, isUser);
    }

    return TextSpan(children: spans);
  }

  // Process text containing *italic* formatting
  void _processItalicText(
    String text,
    List<TextSpan> spans,
    BuildContext context,
    bool isUser,
  ) {
    // Regex for matching text between single asterisks
    final italicRegex = RegExp(r'\*(.*?)\*');
    int position = 0;

    for (final match in italicRegex.allMatches(text)) {
      // Add text before italic
      if (match.start > position) {
        spans.add(
          TextSpan(
            text: text.substring(position, match.start),
            style: TextStyle(
              fontSize: 15,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
              height: 1.4,
            ),
          ),
        );
      }

      // Add italic text
      spans.add(
        TextSpan(
          text: match.group(1) ?? '',
          style: TextStyle(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color:
                isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
            height: 1.4,
          ),
        ),
      );

      position = match.end;
    }

    // Add any remaining text
    if (position < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(position),
          style: TextStyle(
            fontSize: 15,
            color:
                isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
            height: 1.4,
          ),
        ),
      );
    }
  }

  // The original formatting logic, kept as a fallback
  TextSpan _processOriginalFormatting(
    String text,
    BuildContext context,
    bool isUser,
  ) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    bool isInList = false;
    bool isInCodeBlock = false;
    bool isInBlockquote = false;
    String codeContent = '';

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      String trimmedLine = line.trim();

      // Handle code blocks (starts and ends with ```)
      if (trimmedLine.startsWith('```') && !isInCodeBlock) {
        isInCodeBlock = true;
        // Add a newline before code block if needed
        if (spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        continue;
      } else if (trimmedLine.startsWith('```') && isInCodeBlock) {
        // End of code block
        isInCodeBlock = false;
        spans.add(
          TextSpan(
            text: codeContent,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.teal.shade700,
              backgroundColor:
                  isUser
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.grey.shade200,
              height: 1.5,
            ),
          ),
        );
        // Add newline after code block
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
        codeContent = '';
        continue;
      }

      if (isInCodeBlock) {
        // Collecting code content
        codeContent += '$line${i < lines.length - 1 ? '\n' : ''}';
        continue;
      }

      if (trimmedLine.isEmpty) {
        if (i < lines.length - 1) {
          // Only add newline if not the last line
          spans.add(const TextSpan(text: '\n'));
        }
        isInBlockquote = false; // End blockquote on empty line
        continue;
      }

      // Handle headings
      if (trimmedLine.startsWith('### ')) {
        spans.add(
          TextSpan(
            text:
                '${trimmedLine.substring(4)}${i < lines.length - 1 ? '\n' : ''}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
              height: 1.8,
            ),
          ),
        );
      }
      // Handle smaller headings
      else if (trimmedLine.startsWith('## ')) {
        spans.add(
          TextSpan(
            text:
                '${trimmedLine.substring(3)}${i < lines.length - 1 ? '\n' : ''}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
              height: 1.8,
            ),
          ),
        );
      }
      // Handle main headings
      else if (trimmedLine.startsWith('# ')) {
        spans.add(
          TextSpan(
            text:
                '${trimmedLine.substring(2)}${i < lines.length - 1 ? '\n' : ''}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
              height: 1.8,
            ),
          ),
        );
      }
      // Handle blockquotes
      else if (trimmedLine.startsWith('> ')) {
        if (!isInBlockquote && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        isInBlockquote = true;
        spans.add(
          TextSpan(
            text: trimmedLine.substring(2) + (i < lines.length - 1 ? '\n' : ''),
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color:
                  isUser
                      ? Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.9)
                      : Colors.blueGrey.shade700,
              height: 1.5,
              background:
                  Paint()
                    ..color =
                        isUser
                            ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.2)
                            : Colors.blueGrey.shade100
                    ..strokeWidth = 4
                    ..style = PaintingStyle.stroke,
            ),
          ),
        );
      }
      // Handle bullet points
      else if (trimmedLine.startsWith('- ')) {
        if (!isInList && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        isInList = true;
        spans.add(
          TextSpan(
            text:
                '• ${trimmedLine.substring(2)}${i < lines.length - 1 ? '\n' : ''}',
            style: TextStyle(
              fontSize: 15,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
              height: 1.4,
            ),
          ),
        );
      }
      // Handle numbered lists
      else if (RegExp(r'^\d+\.\s').hasMatch(trimmedLine)) {
        if (!isInList && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        isInList = true;
        final match = RegExp(r'^\d+\.\s').firstMatch(trimmedLine);
        if (match != null) {
          final number = match.group(0)!;
          spans.add(
            TextSpan(
              text:
                  '${trimmedLine.substring(0, number.length - 1)}${trimmedLine.substring(number.length)}${i < lines.length - 1 ? '\n' : ''}',
              style: TextStyle(
                fontSize: 15,
                color:
                    isUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                height: 1.4,
              ),
            ),
          );
        }
      }
      // Handle normal paragraphs
      else {
        // Use our _processTextLine method
        _processTextLine(line, i, lines.length, spans, context, isUser);
      }
    }

    return TextSpan(children: spans);
  }

  // Helper method to process a text line with standard formatting
  void _processTextLine(
    String line,
    int lineIndex,
    int totalLines,
    List<TextSpan> spans,
    BuildContext context,
    bool isUser,
  ) {
    String trimmedLine = line.trim();

    if (trimmedLine.isEmpty) {
      if (lineIndex < totalLines - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
      return;
    }

    spans.add(
      TextSpan(
        text: line + (lineIndex < totalLines - 1 ? '\n' : ''),
        style: TextStyle(
          fontSize: 15,
          color:
              isUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildMessage(
    String text,
    bool isUser,
    BuildContext context,
    bool isLight,
  ) {
    // Clean up any potential encoding issues and preprocess markdown
    final cleanText = text.replaceAll('ð', '😊').replaceAll('', '').trim();

    // Preprocess the text to remove markdown indicators before display
    final processedText = _preprocessMarkdown(cleanText);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:
            isUser
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
      child: SelectableText.rich(
        _buildFormattedText(processedText, context, isUser),
        textAlign: TextAlign.left,
      ),
    );
  }

  // Preprocess markdown text to transform it for proper display
  String _preprocessMarkdown(String text) {
    // We're now handling the markdown processing in the controller
    // This method is kept for potential future enhancements
    return text;
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
                      mainAxisAlignment:
                          isUser
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
                              color:
                                  isLight ? Colors.white : Colors.grey.shade800,
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
                          child:
                              isUser
                                  ? _buildMessage(
                                    messageText,
                                    isUser,
                                    context,
                                    isLight,
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                  messageText,
                                                  locale: 'en-IN',
                                                );
                                              },
                                            ),
                                            if (isSpeaking)
                                              AnimatedDots(
                                                color:
                                                    Theme.of(
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
          //     tooltip: 'Toggle Theme',
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
