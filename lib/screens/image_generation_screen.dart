import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/image_generation_controller.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:shimmer/shimmer.dart';

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
                  if (controller.generatedImageUrl.isEmpty &&
                      !controller.isLoading.value)
                    Center(
                      child: Text(
                        'Enter a prompt to generate an image',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  else if (controller.isLoading.value)
                    Center(
                      child: Shimmer.fromColors(
                        baseColor: isLight
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                        highlightColor: isLight
                            ? Colors.grey.shade100
                            : Colors.grey.shade700,
                        child: Container(
                          width: 512,
                          height: 512,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else if (controller.generatedImageUrl.isNotEmpty)
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
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: controller.isDownloading.value
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: controller.isDownloading.value
                                        ? null
                                        : () async {
                                            await controller.downloadImage();
                                            // Show success animation
                                            if (!controller
                                                .isDownloading.value) {
                                              controller.showDownloadSuccess();
                                            }
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    hoverColor: Colors.white.withOpacity(0.1),
                                    splashColor: Colors.white.withOpacity(0.15),
                                    highlightColor:
                                        Colors.white.withOpacity(0.1),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Obx(() {
                                        if (controller.downloadSuccess.value) {
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.green.shade400,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Saved!',
                                                style: TextStyle(
                                                  color: Colors.green.shade400,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            controller.isDownloading.value
                                                ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.download_rounded,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    size: 16,
                                                  ),
                                            const SizedBox(width: 8),
                                            Text(
                                              controller.isDownloading.value
                                                  ? 'Saving...'
                                                  : 'Save to Gallery',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => controller.sourceImageBase64.value.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  base64Decode(controller
                                      .sourceImageBase64.value
                                      .replaceFirst(
                                          RegExp(r'data:image/[^;]+;base64,'),
                                          '')),
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '1374514.png',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  controller.clearSourceImage();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox()),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.promptController,
                          enabled: !controller.isLoading.value,
                          style: TextStyle(
                            color: Colors.white.withOpacity(
                              controller.isLoading.value ? 0.5 : 1.0,
                            ),
                            fontSize: 14,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: controller.isLoading.value
                                ? 'Generating image...'
                                : 'Describe the image you want to generate',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            enabled: !controller.isLoading.value,
                          ),
                          cursorColor: Colors.white.withOpacity(0.7),
                          cursorWidth: 1,
                          cursorHeight: 16,
                          textAlignVertical: TextAlignVertical.center,
                          readOnly: controller.isLoading.value,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: !controller.isLoading.value
                              ? controller.pickImage
                              : null,
                          tooltip: 'Upload image',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: !controller.isLoading.value
                              ? () => _showOptionsSheet(context, controller)
                              : null,
                          tooltip: 'Options',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Obx(() => Text(
                                controller.selectedSize.value,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              )),
                        ),
                        const Spacer(),
                        Obx(() {
                          final bool isEnabled = !controller.isLoading.value &&
                              controller.promptText.value.isNotEmpty;
                          return TextButton(
                            onPressed: isEnabled
                                ? () => controller.generateImage()
                                : null,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Generate',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(
      BuildContext context, ImageGenerationController controller) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Generation Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.sourceImageBase64.value.isNotEmpty) ...[
                Text(
                  'Image Strength',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => Slider(
                            value: controller.imageStrength.value,
                            onChanged: controller.updateImageStrength,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label:
                                '${(controller.imageStrength.value * 100).toStringAsFixed(0)}%',
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Negative Prompt',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Things to avoid in the image...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: controller.updateNegativePrompt,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Image Size',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.availableSizes
                    .map((size) => Obx(() {
                          final isSelected =
                              controller.selectedSize.value == size;
                          return ChoiceChip(
                            label: Text(size),
                            selected: isSelected,
                            onSelected: (_) => controller.updateSize(size),
                            selectedColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            backgroundColor: theme.colorScheme.surface,
                          );
                        }))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Output Format',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.availableFormats
                    .map((format) => Obx(() {
                          final isSelected =
                              controller.selectedFormat.value == format;
                          return ChoiceChip(
                            label: Text(format.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) => controller.updateFormat(format),
                            selectedColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            backgroundColor: theme.colorScheme.surface,
                          );
                        }))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
