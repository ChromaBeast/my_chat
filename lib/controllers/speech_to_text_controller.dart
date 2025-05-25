import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextController extends GetxController {
  final stt.SpeechToText speech = stt.SpeechToText();
  final RxBool isListening = false.obs;
  final RxString recognizedText = ''.obs;

  // Language selection
  final RxList<stt.LocaleName> locales = <stt.LocaleName>[].obs;
  final RxString selectedLocaleId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLocales();
    // Listen to status changes
    speech.statusListener = (status) {
      if (status == 'notListening') {
        isListening.value = false;
      } else if (status == 'listening') {
        isListening.value = true;
      }
    };
  }

  Future<void> _loadLocales() async {
    bool available = await speech.initialize();
    if (available) {
      final localeList = await speech.locales();
      locales.value = localeList;
      if (locales.isNotEmpty) {
        selectedLocaleId.value = locales.first.localeId;
      }
    }
  }

  Future<void> listen({String? localeId}) async {
    if (!isListening.value) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        Get.defaultDialog(
          title: 'Permission Denied',
          middleText:
              'Microphone permission is required for speech recognition.',
        );
        return;
      }
      bool available = await speech.initialize();
      if (available) {
        speech.listen(
          onResult: (result) {
            recognizedText.value = result.recognizedWords;
          },
          localeId:
              localeId ??
              (selectedLocaleId.value.isNotEmpty
                  ? selectedLocaleId.value
                  : null),
        );
      }
    } else {
      await speech.stop();
      // isListening will be set to false by statusListener
    }
  }

  @override
  void onClose() {
    speech.stop();
    super.onClose();
  }
}
