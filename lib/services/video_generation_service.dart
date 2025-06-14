import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import '../models/video_generation_model.dart'; // Removed

class VideoGenerationService {
  // static const String _baseUrl = 'https://api.example.com/video-generation/'; // Removed
  static const int _maxRetries = 60;
  static const Duration _retryDelay = Duration(
    seconds: 5,
  ); // Increased retry delay

  late final Dio _dio;

  VideoGenerationService() {
    final baseUrl = dotenv.env['AZURE_SORA_TARGET_URI'];
    if (baseUrl == null) {
      throw Exception(
        'AZURE_SORA_TARGET_URI not found in environment variables',
      );
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => log(object.toString()),
      ),
    );
  }

  Future<String> generateVideo(
    String prompt, {
    int? width,
    int? height,
    int? n_seconds,
  }) async {
    final apiKey = dotenv.env['AZURE_SORA_TOKEN'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('AZURE_SORA_TOKEN not found in environment variables');
    }

    final headers = {"Content-Type": "application/json", "api-key": apiKey};

    // 1. Create a video generation job
    log('Creating video generation job...');
    final createBody = {
      "prompt": prompt,
      "width": width ?? 480, // Use provided width or default
      "height": height ?? 480, // Use provided height or default
      "n_seconds": n_seconds ?? 5, // Use provided n_seconds or default
      "model": "sora",
      "n_variants": 1,
    };

    Response createResponse;
    try {
      createResponse = await _dio.post(
        '/openai/v1/video/generations/jobs?api-version=preview',
        data: createBody,
        options: Options(headers: headers),
      );
      if (createResponse.statusCode != 200 &&
          createResponse.statusCode != 201) {
        throw DioException(
          requestOptions: createResponse.requestOptions,
          response: createResponse,
          message:
              'Failed to create job: ${createResponse.statusCode} ${createResponse.data}',
        );
      }
    } on DioException catch (e) {
      log('Dio Error creating job: ${e.message}');
      rethrow;
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }

    final jobId = createResponse.data["id"];
    log('Job created: $jobId');

    // 2. Poll for job status
    String status = "";
    Map<String, dynamic> statusResponseData = {};
    int retryCount = 0;
    while (status != "succeeded" &&
        status != "failed" &&
        status != "cancelled" &&
        retryCount < _maxRetries) {
      await Future.delayed(_retryDelay);
      final statusUrl =
          '/openai/v1/video/generations/jobs/$jobId?api-version=preview';

      try {
        final statusResponse = await _dio.get(
          statusUrl,
          options: Options(headers: headers),
        );
        if (statusResponse.statusCode != 200) {
          throw DioException(
            requestOptions: statusResponse.requestOptions,
            response: statusResponse,
            message:
                'Failed to get job status: ${statusResponse.statusCode} ${statusResponse.data}',
          );
        }
        statusResponseData = statusResponse.data;
        status = statusResponseData["status"] ?? "";
        log('Job status: $status (attempt ${retryCount + 1})');
      } on DioException catch (e) {
        log('Dio Error polling status: ${e.message}');
        if (retryCount < _maxRetries - 1) {
          retryCount++;
          continue;
        } else {
          rethrow;
        }
      } catch (e) {
        throw Exception('Failed to poll job status: $e');
      }
      retryCount++;
    }

    // 3. Retrieve generated video
    if (status == "succeeded") {
      final generations = statusResponseData["generations"] as List;
      if (generations.isNotEmpty) {
        log('Video generation succeeded.');
        final generationId = generations[0]["id"];
        final videoUrl =
            '/openai/v1/video/generations/$generationId/content/video?api-version=preview';

        // The actual video content is typically returned as a stream or bytes
        // Here, we expect the URL to be returned, which the client can then play.
        // If the API returns the video content directly, this part needs adjustment.
        return "${_dio.options.baseUrl}$videoUrl"; // Construct full URL
      } else {
        throw Exception("No generations found in job result.");
      }
    } else {
      throw Exception("Job didn't succeed. Final status: $status");
    }
  }
}
