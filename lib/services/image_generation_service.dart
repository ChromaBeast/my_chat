import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageGenerationService {
  static const String _baseUrl =
      'https://Stable-Diffusion-3-5-Large-khwjw.eastus2.models.ai.azure.com/';

  late final Dio _dio;

  ImageGenerationService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => log(object.toString()),
    ));
  }

  Future<String> generateImage(String prompt,
      {String? imagePath, double imageStrength = 0.8}) async {
    final apiKey = dotenv.env['AZURE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API key not found in environment variables');
    }

    final Map<String, dynamic> requestData = {
      "prompt": prompt,
      "negative_prompt": "",
      "size": "1024x1024",
      "output_format": "png",
      "seed": 0
    };

    // Add image_prompt if imagePath is provided
    if (imagePath != null) {
      requestData["image_prompt"] = {
        "image": imagePath,
        "strength": imageStrength
      };
    }

    try {
      log('Starting image generation request...');
      final stopwatch = Stopwatch()..start();

      final response = await _dio.post(
        'images/generations',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $apiKey'
          },
          responseType: ResponseType.plain,
        ),
      );

      stopwatch.stop();
      log('Request completed in ${stopwatch.elapsed.inSeconds} seconds');
      log('Response Status: ${response.statusCode}');

      if (response.data == null) {
        throw Exception('Received null response from server');
      }

      // Try to decode the response as JSON first
      try {
        final decodedResponse = json.decode(response.data.toString());
        if (decodedResponse is Map<String, dynamic>) {
          if (decodedResponse.containsKey('error')) {
            throw Exception(decodedResponse['error'].toString());
          }
          final String? base64Image = decodedResponse['image'];
          if (base64Image != null) {
            return 'data:image/png;base64,$base64Image';
          }
        }
      } catch (e) {
        // If JSON decode fails, try treating it as direct base64
        final responseStr = response.data.toString().trim();
        try {
          base64Decode(responseStr);
          return 'data:image/png;base64,$responseStr';
        } catch (e) {
          log('Base64 validation failed: $e');
          throw Exception('Invalid response format');
        }
      }

      throw Exception('Unexpected response format from server');
    } on DioException catch (e) {
      log('Dio Error Details:');
      log('Message: ${e.message}');
      log('Error Type: ${e.type}');
      log('Status Code: ${e.response?.statusCode}');
      log('Response Data: ${e.response?.data}');

      String errorMessage = 'Failed to generate image';
      if (e.response?.data != null) {
        try {
          final errorData = json.decode(e.response!.data.toString());
          if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {
          errorMessage = e.response!.data.toString();
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      log('Error generating image: $e');
      throw Exception('Failed to generate image: $e');
    }
  }
}

// Helper functions
int min(int a, int b) => a < b ? a : b;
int max(int a, int b) => a > b ? a : b;
