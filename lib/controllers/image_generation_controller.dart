import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/image_generation_service.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageGenerationController extends GetxController {
  final isLoading = false.obs;
  final isDownloading = false.obs;
  final generatedImageUrl = RxString('');
  final promptText = ''.obs;
  final promptController = TextEditingController();
  final _imageService = ImageGenerationService();

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

  Future<void> downloadImage() async {
    if (generatedImageUrl.isEmpty) return;

    try {
      isDownloading.value = true;

      // Request permission first
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Convert base64 to file
      final bytes = base64Decode(generatedImageUrl.value
          .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), ''));

      // Get temporary directory to save the file first
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/AI_Generated_${DateTime.now().millisecondsSinceEpoch}.png';

      // Write bytes to temporary file
      final imageFile = File(tempPath);
      await imageFile.writeAsBytes(bytes);

      // Save to gallery using gallery_saver
      final success = await GallerySaver.saveImage(tempPath);

      if (success ?? false) {
        Get.snackbar(
          'Success',
          'Image saved to gallery!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(8),
          borderRadius: 10,
        );
      } else {
        throw Exception('Failed to save image');
      }

      // Clean up temporary file
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      log('Error saving image: $e');
      Get.snackbar(
        'Error',
        e.toString().contains('permission')
            ? 'Permission denied. Please grant storage access in settings.'
            : 'Failed to save image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        mainButton: e.toString().contains('permission')
            ? TextButton(
                onPressed: () async {
                  await Permission.storage.request();
                },
                child: const Text('Retry'),
              )
            : null,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return Permission.storage.status.isGranted;
    } else if (Platform.isIOS) {
      if (await Permission.photos.status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      return Permission.photos.status.isGranted;
    }
    return false;
  }

  Future<void> generateImage() async {
    if (promptController.text.trim().isEmpty) return;

    isLoading.value = true;
    try {
      final imageUrl =
          await _imageService.generateImage(promptController.text.trim());
      if (imageUrl.isNotEmpty) {
        generatedImageUrl.value = imageUrl;
      } else {
        throw Exception('No image URL received from the API');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearImage() {
    generatedImageUrl.value = '';
    promptController.clear();
  }
}
