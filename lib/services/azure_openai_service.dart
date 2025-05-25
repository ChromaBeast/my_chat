import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:developer' as developer;

class AzureOpenAIService extends GetxService {
  final String apiKey = dotenv.env['AZURE_OPENAI_KEY'] ?? '';
  final String endpoint = dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? '';
  final String deploymentName = dotenv.env['AZURE_OPENAI_DEPLOYMENT'] ?? '';
  final RxList<Map<String, String>> conversationHistory =
      <Map<String, String>>[].obs;

  String _cleanResponse(String text) {
    // Process markdown formatting
    // Replace **text** with a special marker for bold text
    final regexBold = RegExp(r'\*\*(.*?)\*\*', dotAll: true);
    text = text.replaceAllMapped(regexBold, (match) {
      return '<<bold>>${match.group(1)}<</bold>>';
    });

    // Replace common broken emoji patterns
    final cleanText =
        text
            .replaceAll('ð', '😊')
            .replaceAll('', '')
            // Add more emoji replacements as needed
            .replaceAll(':)', '😊')
            .replaceAll(':-)', '😊')
            .replaceAll(':D', '😃')
            .replaceAll(':-D', '😃')
            .replaceAll(';)', '😉')
            .replaceAll(';-)', '😉')
            .replaceAll(':P', '😛')
            .replaceAll(':-P', '😛')
            .replaceAll(':p', '😛')
            .replaceAll(':-p', '😛')
            .trim();

    return cleanText;
  }

  Future<String> getChatCompletion(String message) async {
    final url =
        '$endpoint/openai/deployments/$deploymentName/chat/completions?api-version=2024-08-01-preview';

    // Add user message to history
    conversationHistory.add({'role': 'user', 'content': message});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
        body: jsonEncode({
          'messages': conversationHistory.toList(),
          'max_tokens': 800,
          'temperature': 0.7,
          'frequency_penalty': 0,
          'presence_penalty': 0,
          'top_p': 0.95,
          'stop': null,
        }),
      );

      if (response.statusCode == 200) {
        // Ensure proper UTF-8 decoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        final botResponse = data['choices'][0]['message']['content'] as String;

        // Log the raw response for debugging
        developer.log(
          'Raw response: $botResponse',
          name: 'AzureOpenAI/Response',
        );

        // Clean up the response
        final cleanResponse = _cleanResponse(botResponse);

        // Log the cleaned response
        developer.log(
          'Cleaned response: $cleanResponse',
          name: 'AzureOpenAI/CleanedResponse',
        );

        // Add bot response to history
        conversationHistory.add({
          'role': 'assistant',
          'content': cleanResponse,
        });

        return cleanResponse;
      } else {
        developer.log(
          'Error response: ${response.body}',
          name: 'AzureOpenAI/Error',
          error: 'Status code: ${response.statusCode}',
        );
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error in getChatCompletion: $e',
        name: 'AzureOpenAI/Error',
        error: e,
      );
      throw Exception('Error: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Add system message to set the context
    conversationHistory.add({
      'role': 'system',
      'content':
          'You are a helpful AI assistant. Respond in a friendly and concise manner. When using emojis, use proper Unicode emojis.',
    });
  }

  @override
  void onClose() {
    conversationHistory.clear();
    super.onClose();
  }
}
