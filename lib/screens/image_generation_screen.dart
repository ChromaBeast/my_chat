import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/image_generation_controller.dart';
import 'dart:convert';
import 'dart:developer';

class ImageGenerationScreen extends StatelessWidget {
  const ImageGenerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageGenerationController());
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

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
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Image Generation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.generatedImageUrl.isEmpty) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: controller.clearImage,
              tooltip: 'Clear and start over',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: controller.isLoading.value ? 1 : 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              )),
          Expanded(
            child: Obx(() {
              return Stack(
                children: [
                  if (controller.generatedImageUrl.isEmpty)
                    Center(
                      child: Text(
                        'Enter a prompt to generate an image',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 512),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: RepaintBoundary(
                                  child: Image.memory(
                                    base64Decode(controller
                                        .generatedImageUrl.value
                                        .replaceFirst(
                                            RegExp(r'data:image/[^;]+;base64,'),
                                            '')),
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.medium,
                                    cacheWidth: 1024,
                                    cacheHeight: 1024,
                                    frameBuilder: (context, child, frame,
                                        wasSynchronouslyLoaded) {
                                      if (frame == null) {
                                        return Container(
                                          height: 400,
                                          color: theme.colorScheme.surface,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        );
                                      }
                                      return child;
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 400,
                                        color: theme.colorScheme.error
                                            .withOpacity(0.1),
                                        child: Center(
                                          child: Text(
                                            'Failed to load image',
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            IconButton(
                              onPressed: controller.isDownloading.value
                                  ? null
                                  : controller.downloadImage,
                              icon: Obx(() => controller.isDownloading.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.download_outlined,
                                      color: theme.colorScheme.primary,
                                    )),
                              tooltip: 'Download image',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.promptController,
                            enabled: !controller.isLoading.value,
                            decoration: InputDecoration(
                              hintText: controller.isLoading.value
                                  ? 'Generating image...'
                                  : 'Describe the image you want to create...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => controller.isLoading.value
                                ? null
                                : controller.generateImage(),
                          ),
                        ),
                        Obx(() {
                          final bool isEnabled =
                              controller.promptText.value.isNotEmpty &&
                                  !controller.isLoading.value;
                          return IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: isEnabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withOpacity(0.3),
                              size: 20,
                            ),
                            onPressed:
                                isEnabled ? controller.generateImage : null,
                            splashRadius: 20,
                            tooltip: 'Generate image',
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
