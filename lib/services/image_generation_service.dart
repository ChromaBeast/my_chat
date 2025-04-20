import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/image_generation_model.dart';

class ImageGenerationService {
  static const String _baseUrl =
      'https://Stable-Diffusion-3-5-Large-khwjw.eastus2.models.ai.azure.com/';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  late final Dio _dio;

  ImageGenerationService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
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

  Future<String> generateImage(
    String prompt, {
    String negativePrompt = '',
    String size = '1024x1024',
    String outputFormat = 'png',
    String? sourceImageBase64,
    double imageStrength = 0.8,
  }) async {
    final apiKey = dotenv.env['AZURE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API key not found in environment variables');
    }

    final request = ImageGenerationRequest(
      prompt: prompt,
      negativePrompt: negativePrompt,
      size: size,
      outputFormat: outputFormat,
      imagePrompt: sourceImageBase64 != null && sourceImageBase64.isNotEmpty
          ? ImagePrompt(
              image: sourceImageBase64,
              strength: imageStrength,
            )
          : null,
    );

    int retryCount = 0;
    DioException? lastError;

    while (retryCount < _maxRetries) {
      try {
        log('Starting image generation request (attempt ${retryCount + 1})...');
        final stopwatch = Stopwatch()..start();

        final response = await _dio.post(
          'images/generations',
          data: request.toJson(),
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
          final imageResponse =
              ImageGenerationResponse.fromJson(decodedResponse);

          if (imageResponse.isError) {
            throw Exception(imageResponse.error!.userFriendlyMessage);
          }

          if (imageResponse.image != null) {
            return 'data:image/png;base64,${imageResponse.image}';
          }

          // If JSON decode succeeds but no image, try treating it as direct base64
          final responseStr = response.data.toString().trim();
          try {
            base64Decode(responseStr);
            return 'data:image/png;base64,$responseStr';
          } catch (e) {
            log('Base64 validation failed: $e');
            throw Exception('Invalid response format');
          }
        } catch (e) {
          log('Error parsing response: $e');
          throw Exception('Failed to parse server response');
        }
      } on DioException catch (e) {
        lastError = e;
        log('Dio Error Details (attempt ${retryCount + 1}):');
        log('Message: ${e.message}');
        log('Error Type: ${e.type}');
        log('Status Code: ${e.response?.statusCode}');
        log('Response Data: ${e.response?.data}');

        // Don't retry if it's a moderation error or other specific errors
        if (e.response != null && e.response!.statusCode != null) {
          rethrow;
        }

        // For network-related errors, retry after delay
        if (retryCount < _maxRetries - 1) {
          log('Retrying in ${_retryDelay.inSeconds} seconds...');
          await Future.delayed(_retryDelay);
          retryCount++;
          continue;
        }
      } catch (e) {
        log('Error generating image: $e');
        throw Exception('Failed to generate image: $e');
      }
    }

    // If we've exhausted all retries, throw a user-friendly error
    String errorMessage = 'Failed to connect to the image generation service. ';
    if (lastError?.error is SocketException) {
      errorMessage += 'Please check your internet connection and try again.';
    } else if (lastError?.type == DioExceptionType.connectionTimeout) {
      errorMessage += 'The connection timed out. Please try again.';
    } else if (lastError?.message?.contains('Connection reset by peer') ??
        false) {
      errorMessage +=
          'The connection was reset. Please try again in a few moments.';
    } else {
      errorMessage += 'Please try again later.';
    }

    throw Exception(errorMessage);
  }
}

// Helper functions
int min(int a, int b) => a < b ? a : b;
int max(int a, int b) => a > b ? a : b;
