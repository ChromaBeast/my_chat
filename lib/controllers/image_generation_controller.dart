import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_ai/common/custom_toast.dart';
import '../services/image_generation_service.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

enum ImageFormat { png, jpg }

class ImageGenerationController extends GetxController {
  final isLoading = false.obs;
  final isDownloading = false.obs;
  final downloadSuccess = false.obs;
  final generatedImageUrl = RxString('');
  final promptText = ''.obs;
  final promptController = TextEditingController();
  final _imageService = ImageGenerationService();

  // New variables for options
  final selectedSize = Rx<String>('1024x1024');
  final selectedFormat = Rx<ImageFormat>(ImageFormat.png);
  final negativePrompt = ''.obs;
  final imageStrength = 0.8.obs;
  final sourceImageBase64 = RxString('');
  final showOptions = false.obs;

  // Available options
  final List<String> availableSizes = [
    '672x1566', // Portrait - Tall
    '768x1366', // Portrait
    '836x1254', // Portrait - Moderate
    '916x1145', // Portrait - Slight
    '1024x1024', // Square
    '1145x916', // Landscape - Slight
    '1254x836', // Landscape - Moderate
    '1366x768', // Landscape
    '1566x672', // Landscape - Wide
  ];

  final List<ImageFormat> availableFormats = ImageFormat.values;

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

  void updateNegativePrompt(String value) {
    negativePrompt.value = value;
  }

  void updateImageStrength(double value) {
    imageStrength.value = value;
  }

  void updateSize(String size) {
    selectedSize.value = size;
  }

  void updateFormat(ImageFormat format) {
    selectedFormat.value = format;
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image != null) {
        log('Image picked: ${image.path}');
        final bytes = await image.readAsBytes();
        // Add data URI prefix for proper image display
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        log('Image size: ${bytes.length} bytes');
        log('Base64 length: ${base64String.length}');

        sourceImageBase64.value = base64String;
        showOptions.value = true; // Show options sheet when image is picked
      }
    } catch (e) {
      log('Error picking image: $e');
      CustomToast.showError(
        'Failed to pick image: ${e.toString()}',
      );
    }
  }

  void clearSourceImage() {
    sourceImageBase64.value = '';
    imageStrength.value = 0.8;
  }

  void toggleOptions() {
    showOptions.value = !showOptions.value;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13 (API level 33) and above
      if (await Permission.photos.status.isDenied) {
        final photos = await Permission.photos.request();
        if (photos.isDenied) {
          // Also request storage permission as fallback
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

  void showDownloadSuccess() {
    downloadSuccess.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      downloadSuccess.value = false;
    });
  }

  Future<void> downloadImage() async {
    if (generatedImageUrl.isEmpty) return;

    try {
      isDownloading.value = true;
      downloadSuccess.value = false;

      // Request permission first
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
          'Permission denied: Unable to access storage. Please grant permission in Settings.',
        );
      }

      // Convert base64 to file
      final bytes = base64Decode(
        generatedImageUrl.value.replaceFirst(
          RegExp(r'data:image/[^;]+;base64,'),
          '',
        ),
      );

      // Get temporary directory to save the file first
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/AI_Generated_${DateTime.now().millisecondsSinceEpoch}.${selectedFormat.value.name}';

      // Write bytes to temporary file
      final imageFile = File(tempPath);
      await imageFile.writeAsBytes(bytes);

      // Save to gallery using gallery_saver
      final success = await GallerySaver.saveImage(
        tempPath,
        albumName: 'AI Generated Images',
      );

      if (success == true) {
        showDownloadSuccess();
        CustomToast.showSuccess('Image saved to gallery',);
      } else {
        throw Exception('Failed to save image to gallery');
      }

      // Clean up temporary file
      try {
        await imageFile.delete();
      } catch (e) {
        log('Error deleting temporary file: $e');
      }
    } catch (e) {
      log('Error saving image: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Permission denied')) {
        errorMessage =
            'Permission denied: Unable to access storage. Please grant permission in Settings.';
      }
      CustomToast.showError(
        errorMessage,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> generateImage() async {
    if (promptController.text.trim().isEmpty) return;

    isLoading.value = true;
    try {
      log(
        'Generating image with source: ${sourceImageBase64.value.isNotEmpty ? 'Yes' : 'No'}',
      );
      final imageUrl = await _imageService.generateImage(
        promptController.text.trim(),
        negativePrompt: negativePrompt.value,
        size: selectedSize.value,
        outputFormat: selectedFormat.value.name,
        sourceImageBase64: sourceImageBase64.value,
        imageStrength: imageStrength.value,
      );

      if (imageUrl.isNotEmpty) {
        generatedImageUrl.value = imageUrl;
      } else {
        throw Exception('No image URL received from the API');
      }
    } catch (e) {
      String errorMessage = 'Failed to generate image';

      if (e.toString().contains('RAI prompt moderation')) {
        errorMessage =
            'Your prompt contains content that cannot be processed. Please modify your prompt to comply with content guidelines.';
      }

      CustomToast.showError(
        errorMessage,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearImage() {
    generatedImageUrl.value = '';
    promptController.clear();
    sourceImageBase64.value = '';
  }
}
