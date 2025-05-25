import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/speech_to_text_controller.dart';
import 'animated_dots.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendPressed;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSendPressed,
    this.isLoading = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  bool _canSend = false;
  final FocusNode _focusNode = FocusNode();
  late final SpeechToTextController _sttController;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateSendButton);
    _sttController = Get.put(SpeechToTextController(), tag: 'chatInput');
    ever<String>(_sttController.recognizedText, (text) {
      if (text.isNotEmpty) {
        setState(() {
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      }
    });
  }

  void _updateSendButton() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _handleSend() {
    if (_canSend && !widget.isLoading) {
      final message = _textController.text.trim();
      _textController.clear();
      widget.onSendPressed(message);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    Get.delete<SpeechToTextController>(tag: 'chatInput');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !widget.isLoading,
                      decoration: InputDecoration(
                        hintText:
                            widget.isLoading
                                ? 'Waiting for response...'
                                : 'Type a message',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 15,
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _canSend ? (_) => _handleSend() : null,
                    ),
                  ),
                  Obx(() {
                    if (_sttController.isListening.value) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedDots(
                          color: Theme.of(context).colorScheme.primary,
                          size: 10,
                        ),
                      );
                    } else {
                      return IconButton(
                        icon: Icon(
                          Icons.mic,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                        onPressed:
                            widget.isLoading
                                ? null
                                : () async {
                                  await _sttController.listen(
                                    localeId: 'en-IN',
                                  );
                                },
                        splashRadius: 20,
                        tooltip: 'Speak',
                      );
                    }
                  }),
                  AnimatedOpacity(
                    opacity: _canSend && !widget.isLoading ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: _canSend ? _handleSend : null,
                      splashRadius: 20,
                      tooltip: 'Send message',
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
