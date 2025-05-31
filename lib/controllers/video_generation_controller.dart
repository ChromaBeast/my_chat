import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_ai/common/custom_toast.dart';
import '../services/video_generation_service.dart';

class VideoGenerationController extends GetxController {
  final isLoading = false.obs;
  final generatedVideoUrl = RxString('');
  final promptText = ''.obs;
  final promptController = TextEditingController();
  final _videoService = VideoGenerationService();

  @override
  void onInit() {
    super.onInit();
    promptController.addListener(() {
      promptText.value = promptController.text;
    });
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }

  void updatePromptText(String value) {
    promptText.value = value;
  }

  Future<void> generateVideo() async {
    if (promptController.text.trim().isEmpty) return;

    isLoading.value = true;
    try {
      final videoUrl = await _videoService.generateVideo(
        promptController.text.trim(),
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
  }
}
