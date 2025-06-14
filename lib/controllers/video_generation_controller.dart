import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_ai/common/custom_toast.dart';
import '../services/video_generation_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:http/http.dart' as http;

class VideoGenerationController extends GetxController {
  final isLoading = false.obs;
  final generatedVideoUrl = RxString('');
  final promptText = ''.obs;
  final promptController = TextEditingController();
  final _videoService = VideoGenerationService();

  // Video player state
  final Rx<VideoPlayerController?> videoPlayerController =
      Rx<VideoPlayerController?>(null);
  final showControls = true.obs;
  final isPlaying = false.obs;
  final isBuffering = true.obs;
  final isPlayerReady = false.obs;
  Timer? _hideControlsTimer;
  final currentPosition = '00:00'.obs;
  final totalDuration = '00:00'.obs;

  // New state for aspect ratio and resolution
  final selectedAspectRatio = '16:9'.obs;
  final selectedResolution = '480p'.obs;
  final selectedWidth = 480.obs;
  final selectedHeight = 480.obs;

  final selectedDuration = 5.obs;
  final List<int> durationOptions = [5, 10, 15, 20];

  final Map<String, double> aspectRatioMap = {
    '16:9': 16 / 9,
    '1:1': 1 / 1,
    '9:16': 9 / 16,
  };

  // Base resolutions (always 16:9 for calculation)
  final Map<String, Map<String, int>> baseResolutionMap = {
    '480p': {'width': 854, 'height': 480},
    '720p': {'width': 1280, 'height': 720},
    '1080p': {'width': 1920, 'height': 1080},
  };

  @override
  void onInit() {
    super.onInit();
    promptController.addListener(() {
      promptText.value = promptController.text;
    });

    // Listen to changes in generatedVideoUrl to initialize/dispose video player
    ever(generatedVideoUrl, (String? url) {
      if (url != null && url.isNotEmpty) {
        _initializeVideoPlayer(url);
      } else {
        _disposeVideoPlayer();
      }
    });

    // Set initial dimensions based on default selections
    _adjustDimensions();
  }

  @override
  void onClose() {
    promptController.dispose();
    _disposeVideoPlayer();
    super.onClose();
  }

  // --- Video Player Logic ---
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (isPlaying.value) {
        showControls.value = false;
      }
    });
  }

  void toggleControlsVisibility() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _startHideControlsTimer();
    }
  }

  void _videoPlayerListener() {
    // Only proceed if the controller is not closed and player is available
    if (isClosed || videoPlayerController.value == null) {
      debugPrint(
        "VideoPlayerListener: Controller is closed or player is null. Skipping update.",
      );
      return;
    }

    final playerValue = videoPlayerController.value!.value; // Access value once

    isPlaying.value = playerValue.isPlaying;
    isBuffering.value = playerValue.isBuffering;

    if (playerValue.isCompleted) {
      isPlaying.value = false;
      isBuffering.value = false;
      showControls.value = true; // Show controls when video ends
      _hideControlsTimer?.cancel(); // Cancel any existing hide timer
    }

    if (playerValue.isInitialized) {
      currentPosition.value = _formatDuration(playerValue.position);
      totalDuration.value = _formatDuration(playerValue.duration);
    }

    if (isPlaying.value) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _initializeVideoPlayer(String url) {
    _disposeVideoPlayer(); // Dispose previous controller if any

    final apiKey = dotenv.env['AZURE_SORA_TOKEN'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
        'AZURE_SORA_TOKEN not found in environment variables, cannot play video.',
      );
      return;
    }

    videoPlayerController.value = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {'api-key': apiKey},
    );

    videoPlayerController.value!
        .initialize()
        .then((_) {
          videoPlayerController.value?.play();
          videoPlayerController.value?.addListener(_videoPlayerListener);
          _startHideControlsTimer();
          isPlayerReady.value = true;
        })
        .catchError((error) {
          debugPrint('Error initializing video player: $error');
          // Optionally show a message to the user
        });
  }

  void _disposeVideoPlayer() {
    _hideControlsTimer?.cancel();
    videoPlayerController.value?.removeListener(_videoPlayerListener);
    videoPlayerController.value?.dispose();
    videoPlayerController.value = null;
    isPlaying.value = false;
    isBuffering.value = true;
    currentPosition.value = '00:00';
    totalDuration.value = '00:00';
    isPlayerReady.value = false;
  }

  void playPauseVideo() {
    if (videoPlayerController.value == null ||
        !videoPlayerController.value!.value.isInitialized)
      return;

    toggleControlsVisibility(); // Keep controls visible on interaction

    if (videoPlayerController.value!.value.isPlaying) {
      videoPlayerController.value!.pause();
    } else {
      videoPlayerController.value!.play();
    }
  }

  void replayVideo() {
    if (videoPlayerController.value == null ||
        !videoPlayerController.value!.value.isInitialized)
      return;

    toggleControlsVisibility(); // Keep controls visible on interaction

    videoPlayerController.value!.seekTo(Duration.zero);
    videoPlayerController.value!.play();
  }

  Future<void> downloadVideo() async {
    if (generatedVideoUrl.isEmpty) {
      CustomToast.showError('No video to download.');
      return;
    }

    final apiKey = dotenv.env['AZURE_SORA_TOKEN'];
    if (apiKey == null || apiKey.isEmpty) {
      CustomToast.showError('API key not found, cannot download video.');
      return;
    }

    // Request permission first
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      CustomToast.showError(
        'Permission denied: Unable to access storage. Please grant permission in Settings.',
      );
      return;
    }

    CustomToast.showLoading('Starting video download...');

    try {
      final response = await http.get(
        Uri.parse(generatedVideoUrl.value),
        headers: {'api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/SuperAI_Video_${DateTime.now().millisecondsSinceEpoch}.mp4';

        final videoFile = File(tempPath);
        await videoFile.writeAsBytes(response.bodyBytes);

        final success = await GallerySaver.saveVideo(
          tempPath,
          albumName: 'SuperAI',
        );

        if (success == true) {
          CustomToast.showSuccess('Video saved to gallery');
        } else {
          throw Exception('Failed to save video to gallery');
        }

        try {
          await videoFile.delete();
        } catch (e) {
          debugPrint('Error deleting temporary file: $e');
        }
      } else {
        CustomToast.showError(
          'Failed to download video: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Permission denied')) {
        errorMessage =
            'Permission denied: Unable to access storage. Please grant permission in Settings.';
      }
      CustomToast.showError(errorMessage);
    } finally {
      // No explicit isDownloading state needed, custom toast handles it
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.status.isDenied) {
        final photos = await Permission.photos.request();
        if (photos.isDenied) {
          final storage = await Permission.storage.request();
          return storage.isGranted;
        }
        return photos.isGranted;
      }
      return Permission.photos.status.isGranted;
    } else if (Platform.isIOS) {
      if (await Permission.photos.status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      return Permission.photos.status.isGranted;
    }
    return false;
  }

  // --- End Video Player Logic ---

  void updatePromptText(String value) {
    promptText.value = value;
  }

  Future<void> generateVideo() async {
    if (promptController.text.trim().isEmpty) return;

    isLoading.value = true;
    try {
      final selectedResolutionData =
          baseResolutionMap[selectedResolution.value];
      final width = selectedResolutionData!['width']!;
      final height = selectedResolutionData['height']!;

      final videoUrl = await _videoService.generateVideo(
        promptController.text.trim(),
        width: width,
        height: height,
        n_seconds: selectedDuration.value,
      );

      if (videoUrl.isNotEmpty) {
        generatedVideoUrl.value = videoUrl;
      } else {
        throw Exception('No video URL received from the API');
      }
    } catch (e) {
      String errorMessage = 'Failed to generate video: $e';
      CustomToast.showError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  void clearVideo() {
    generatedVideoUrl.value = '';
    promptController.clear();
    _disposeVideoPlayer(); // Ensure video player is disposed when cleared
  }

  void updateAspectRatio(String? newAspectRatio) {
    if (newAspectRatio != null) {
      selectedAspectRatio.value = newAspectRatio;
      _adjustDimensions();
    }
  }

  void updateResolution(String? newResolution) {
    if (newResolution != null) {
      selectedResolution.value = newResolution;
      _adjustDimensions();
    }
  }

  void updateDuration(int? newDuration) {
    if (newDuration != null) {
      selectedDuration.value = newDuration;
    }
  }

  void _adjustDimensions() {
    final currentResolutionKey = selectedResolution.value;
    final currentAspectRatioKey = selectedAspectRatio.value;

    final baseWidth = baseResolutionMap[currentResolutionKey]!['width']!;
    final baseHeight = baseResolutionMap[currentResolutionKey]!['height']!;

    int newWidth = baseWidth;
    int newHeight = baseHeight;

    if (currentAspectRatioKey == '1:1') {
      // For 1:1, take the smaller of the base dimensions as the side
      newWidth = (baseWidth < baseHeight) ? baseWidth : baseHeight;
      newHeight = newWidth; // Square
    } else if (currentAspectRatioKey == '9:16') {
      // For 9:16, swap width and height from the 16:9 base
      newWidth = baseHeight;
      newHeight = baseWidth;
    }

    selectedWidth.value = newWidth;
    selectedHeight.value = newHeight;
  }
}
