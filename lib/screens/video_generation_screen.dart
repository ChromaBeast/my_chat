import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_generation_controller.dart';
import 'package:video_player/video_player.dart';
// import 'package:cached_video_player_plus/cached_video_player_plus.dart';

// Placeholder for Azure credentials. You'll need to replace this with actual
// secure handling of credentials in a production Flutter app.
// For demonstration, we'll use placeholders.
// const String azureOpenAIEndpoint = "YOUR_AZURE_OPENAI_ENDPOINT";
// const String azureOpenAIKey = "YOUR_AZURE_OPENAI_KEY";

class VideoGenerationScreen extends GetView<VideoGenerationController> {
  const VideoGenerationScreen({super.key});

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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Aspect Ratio Dropdown
                Column(
                  children: [
                    Text('Aspect Ratio:', style: theme.textTheme.titleSmall),
                    Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedAspectRatio.value,
                        onChanged: controller.updateAspectRatio,
                        items: controller.aspectRatioMap.keys
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
                // Resolution Dropdown
                Column(
                  children: [
                    Text('Resolution:', style: theme.textTheme.titleSmall),
                    Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedResolution.value,
                        onChanged: controller.updateResolution,
                        items: controller.baseResolutionMap.keys
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
                // Duration Dropdown
                Column(
                  children: [
                    Text('Duration:', style: theme.textTheme.titleSmall),
                    Obx(
                      () => DropdownButton<int>(
                        value: controller.selectedDuration.value,
                        onChanged: controller.updateDuration,
                        items: controller.durationOptions
                            .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value seconds'),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              debugPrint(
                'Obx Rebuild: generatedVideoUrl=${controller.generatedVideoUrl.value}',
              );
              debugPrint(
                'Obx Rebuild: videoPlayerController.value=${controller.videoPlayerController.value}',
              );
              if (controller.videoPlayerController.value != null) {
                debugPrint(
                  'Obx Rebuild: videoPlayerController.value.value.isInitialized=${controller.videoPlayerController.value!.value.isInitialized}',
                );
              }

              if (controller.generatedVideoUrl.isEmpty &&
                  !controller.isLoading.value)
                return Center(
                  child: Text(
                    'Enter a prompt to generate a video',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                );
              else if (controller.isLoading.value)
                return Center(
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
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              else if (controller.generatedVideoUrl.isNotEmpty &&
                  controller.videoPlayerController.value != null &&
                  controller.isPlayerReady.value) {
                debugPrint(
                  'VideoGenerationScreen: VideoPlayerController is initialized and ready.',
                );
                return GestureDetector(
                  onTap: controller.toggleControlsVisibility,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio:
                          controller.aspectRatioMap[controller
                              .selectedAspectRatio
                              .value] ??
                          controller
                              .videoPlayerController
                              .value!
                              .value
                              .aspectRatio,
                      child: Stack(
                        children: [
                          VideoPlayer(
                            controller.videoPlayerController.value!,
                            key: ValueKey(
                              controller.videoPlayerController.value.hashCode,
                            ),
                          ),
                          if (controller.isBuffering.value)
                            Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          AnimatedOpacity(
                            opacity: controller.showControls.value ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top controls (e.g., download button)
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: controller.downloadVideo,
                                      ),
                                    ),
                                  ),
                                  // Center controls (play/pause, replay)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Obx(() {
                                        if (controller.isPlaying.value) {
                                          return const SizedBox.shrink();
                                        }
                                        return IconButton(
                                          icon: const Icon(
                                            Icons.replay,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                          onPressed: controller.replayVideo,
                                        );
                                      }),
                                      Obx(() {
                                        // Only show play/pause if video is not completed
                                        if (controller
                                                    .videoPlayerController
                                                    .value ==
                                                null ||
                                            controller
                                                .videoPlayerController
                                                .value!
                                                .value
                                                .isCompleted) {
                                          return const SizedBox.shrink(); // Hide the button and its spacing completely
                                        }
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(width: 20),
                                            IconButton(
                                              icon: Icon(
                                                controller.isPlaying.value
                                                    ? Icons.pause_circle_filled
                                                    : Icons.play_circle_filled,
                                                color: Colors.white,
                                                size: 64,
                                              ),
                                              onPressed:
                                                  controller.playPauseVideo,
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                  // Bottom controls (progress bar, duration)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: VideoProgressIndicator(
                                      controller.videoPlayerController.value!,
                                      allowScrubbing: true,
                                      colors: VideoProgressColors(
                                        playedColor: theme.colorScheme.primary,
                                        bufferedColor: Colors.white.withOpacity(
                                          0.5,
                                        ),
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          controller.currentPosition.value,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          controller.totalDuration.value,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (controller.generatedVideoUrl.isNotEmpty &&
                  controller.videoPlayerController.value == null) {
                debugPrint(
                  'VideoGenerationScreen: VideoPlayerController is null after URL is set.',
                );
                return Center(
                  child: Text(
                    'Failed to load video',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              // Fallback for any unhandled state, though ideally all states are covered
              return const SizedBox();
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
