import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

class TextToSpeechController extends GetxController {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController textController = TextEditingController();
  final RxBool isSpeaking = false.obs;

  // Add for voice selection
  final RxList<dynamic> voices = <dynamic>[].obs;
  final RxString selectedVoice = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    final v = await flutterTts.getVoices;
    voices.value = v;
    if (voices.isNotEmpty) {
      selectedVoice.value = voices.first['name'] ?? '';
    }
  }

  // Helper to remove emojis from text
  String _removeEmojis(String text) {
    // This regex matches most common emoji ranges
    return text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}' // Emoticons
        r'\u{1F300}-\u{1F5FF}' // Misc Symbols and Pictographs
        r'\u{1F680}-\u{1F6FF}' // Transport and Map
        r'\u{2600}-\u{26FF}' // Misc symbols
        r'\u{2700}-\u{27BF}' // Dingbats
        r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
        r'\u{1FA70}-\u{1FAFF}' // Symbols and Pictographs Extended-A
        r'\u{1F1E6}-\u{1F1FF}' // Flags
        r'\u{1F191}-\u{1F251}' // Enclosed characters
        r'\u{1F004}|\u{1F0CF}' // Mahjong, Playing cards
        r'\u{200D}' // Zero Width Joiner
        r'\u{23CF}|\u{23E9}-\u{23F3}|\u{23F8}-\u{23FA}' // Misc
        r']+',
        unicode: true,
      ),
      '',
    );
  }

  Future<void> speak() async {
    if (textController.text.trim().isEmpty) return;
    isSpeaking.value = true;
    if (selectedVoice.value.isNotEmpty) {
      final voice = voices.firstWhereOrNull(
        (v) => v['name'] == selectedVoice.value,
      );
      if (voice != null) {
        final Map<String, String> voiceParams = {
          "name": (voice['name'] ?? '').toString(),
          "locale": (voice['locale'] ?? '').toString(),
        };
        if (voice['gender'] != null) {
          voiceParams['gender'] = voice['gender'].toString();
        }
        await flutterTts.setVoice(voiceParams);
      }
    }
    final cleanText = _removeEmojis(textController.text.trim());
    await flutterTts.speak(cleanText);
    isSpeaking.value = false;
  }

  Future<void> stop() async {
    await flutterTts.stop();
    isSpeaking.value = false;
  }

  // Helper to speak with a specific locale (e.g., en-IN for chat responses)
  Future<void> speakWithLocale(String text, {String? locale}) async {
    if (text.trim().isEmpty) return;
    isSpeaking.value = true;
    Map<String, String>? voiceParams;
    if (locale != null) {
      final voice = voices.firstWhereOrNull((v) => v['locale'] == locale);
      if (voice != null) {
        voiceParams = {
          "name": (voice['name'] ?? '').toString(),
          "locale": (voice['locale'] ?? '').toString(),
        };
        if (voice['gender'] != null) {
          voiceParams['gender'] = voice['gender'].toString();
        }
      }
    }
    if (voiceParams != null) {
      await flutterTts.setVoice(voiceParams);
    } else if (selectedVoice.value.isNotEmpty) {
      final voice = voices.firstWhereOrNull(
        (v) => v['name'] == selectedVoice.value,
      );
      if (voice != null) {
        final Map<String, String> selectedParams = {
          "name": (voice['name'] ?? '').toString(),
          "locale": (voice['locale'] ?? '').toString(),
        };
        if (voice['gender'] != null) {
          selectedParams['gender'] = voice['gender'].toString();
        }
        await flutterTts.setVoice(selectedParams);
      }
    }
    final cleanText = _removeEmojis(text.trim());
    await flutterTts.speak(cleanText);
    isSpeaking.value = false;
  }

  @override
  void onClose() {
    flutterTts.stop();
    textController.dispose();
    super.onClose();
  }
}
