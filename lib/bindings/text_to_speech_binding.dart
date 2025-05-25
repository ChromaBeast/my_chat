import 'package:get/get.dart';
import '../controllers/text_to_speech_controller.dart';

class TextToSpeechBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TextToSpeechController>(() => TextToSpeechController());
  }
}
