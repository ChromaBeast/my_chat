import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/speech_to_text_controller.dart';
import '../widgets/animated_dots.dart';
import '../widgets/custom_text_field.dart';

class SpeechToTextScreen extends GetView<SpeechToTextController> {
  const SpeechToTextScreen({super.key});

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
              'Speech to Text',
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
            // Language selection dropdown
            Obx(() {
              if (controller.locales.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
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
                            controller.selectedLocaleId.value.isNotEmpty
                                ? controller.selectedLocaleId.value
                                : null,
                        items:
                            controller.locales.map<DropdownMenuItem<String>>((
                              locale,
                            ) {
                              final label =
                                  locale.name.isNotEmpty
                                      ? '${locale.name} (${locale.localeId})'
                                      : locale.localeId;
                              return DropdownMenuItem(
                                value: locale.localeId,
                                child: Row(
                                  children: [
                                    const Icon(Icons.language, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null)
                            controller.selectedLocaleId.value = value;
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
              'Recognized Speech',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Card(
                color: theme.colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: SelectableText(
                    controller.recognizedText.value.isEmpty
                        ? 'Your speech will appear here...'
                        : controller.recognizedText.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Obx(
              () =>
                  controller.isListening.value
                      ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Center(
                            child: AnimatedDots(
                              color: theme.colorScheme.primary,
                              size: 10,
                            ),
                          ),
                        ],
                      )
                      : ElevatedButton.icon(
                        icon: Icon(
                          Icons.mic,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          'Start Listening',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        onPressed: () => controller.listen(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
