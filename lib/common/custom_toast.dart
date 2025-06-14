import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomToast {
  static void showSuccess(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
    );
  }

  static void showError(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const Icon(Icons.error, color: Colors.white, size: 20),
    );
  }

  static void showLoading(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.blueAccent,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),
      isDismissible: false,
    );
  }
}
