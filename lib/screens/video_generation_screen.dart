import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_generation_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Placeholder for Azure credentials. You'll need to replace this with actual
// secure handling of credentials in a production Flutter app.
// For demonstration, we'll use placeholders.
// const String azureOpenAIEndpoint = "YOUR_AZURE_OPENAI_ENDPOINT";
// const String azureOpenAIKey = "YOUR_AZURE_OPENAI_KEY";

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({super.key});

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  late VideoGenerationController controller;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VideoGenerationController>();
    ever(controller.generatedVideoUrl, (String? url) {
      if (url != null && url.isNotEmpty) {
        _initializeVideoPlayer(url);
      } else {
        _disposeVideoPlayer();
      }
    });
  }

  void _initializeVideoPlayer(String url) {
    _disposeVideoPlayer(); // Dispose previous controller if any
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController?.play();
      });
  }

  void _disposeVideoPlayer() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    super.dispose();
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
              'Video Generation',
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
            if (controller.generatedVideoUrl.isEmpty) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: controller.clearVideo,
              tooltip: 'Clear and start over',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Divider(height: 1, color: theme.colorScheme.primary.withOpacity(0.1)),
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: controller.isLoading.value ? 1 : 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              return Stack(
                children: [
                  if (controller.generatedVideoUrl.isEmpty &&
                      !controller.isLoading.value)
                    Center(
                      child: Text(
                        'Enter a prompt to generate a video',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  else if (controller.isLoading.value)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generating video...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (controller.generatedVideoUrl.isNotEmpty &&
                      _videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    )
                  else if (controller.generatedVideoUrl.isNotEmpty &&
                      _videoPlayerController == null)
                    Center(
                      child: Text(
                        'Failed to load video',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: theme.colorScheme.surface,
              elevation: isLight ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                                ? 'Generating video...'
                                : 'Describe the video you want to generate',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              16,
                            ),
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
                    color: Colors.white.withOpacity(0.1),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Obx(() {
                          final bool isEnabled =
                              !controller.isLoading.value &&
                              controller.promptText.value.isNotEmpty;
                          return TextButton(
                            onPressed: isEnabled
                                ? controller.generateVideo
                                : null,
                            style: TextButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.08),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Generate',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
}
