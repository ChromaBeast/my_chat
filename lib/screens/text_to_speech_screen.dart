import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/text_to_speech_controller.dart';
import '../widgets/animated_dots.dart';
import '../widgets/custom_text_field.dart';

class TextToSpeechScreen extends GetView<TextToSpeechController> {
  const TextToSpeechScreen({super.key});

  String getLanguageName(String locale) {
    const languageMap = {
      'en-IN': 'English (India)',
      'en-US': 'English (United States)',
      'en-GB': 'English (UK)',
      'hi-IN': 'Hindi (India)',
      'fr-FR': 'French (France)',
      'es-ES': 'Spanish (Spain)',
      'de-DE': 'German (Germany)',
      'it-IT': 'Italian (Italy)',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
      'zh-CN': 'Chinese (Mandarin)',
      'ru-RU': 'Russian',
      'pt-BR': 'Portuguese (Brazil)',
      'ar-SA': 'Arabic (Saudi Arabia)',
      // Add more as needed
    };
    return languageMap[locale] ?? locale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Scaffold(
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
              'Text to Speech',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              if (controller.voices.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: theme.colorScheme.surface,
                    elevation: isLight ? 1 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: DropdownButton<String>(
                        value:
                            controller.selectedVoice.value.isNotEmpty
                                ? controller.selectedVoice.value
                                : null,
                        items:
                            controller.voices.map<DropdownMenuItem<String>>((
                              voice,
                            ) {
                              final name = voice['name'] ?? '';
                              final lang = voice['locale'] ?? '';
                              final gender = voice['gender'] ?? '';
                              return DropdownMenuItem(
                                value: name,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.record_voice_over,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          Row(
                                            children: [
                                              if (lang.isNotEmpty)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 4,
                                                    right: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    getLanguageName(lang),
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .primary,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                              if (gender.isNotEmpty)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    gender,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .secondary,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null)
                            controller.selectedVoice.value = value;
                        },
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        dropdownColor: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Enter text to speak',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.textController,
              labelText: '',
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () =>
            controller.isSpeaking.value
                ? Column(
                  children: [
                    const SizedBox(height: 16),
                    AnimatedDots(color: theme.colorScheme.primary, size: 10),
                  ],
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mic),
                    label: Text('Speak'),
                    onPressed:
                        controller.isSpeaking.value ? null : controller.speak,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
      ),
    );
  }
}
