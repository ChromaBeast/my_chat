import 'package:get/get.dart';
import '../controllers/speech_to_text_controller.dart';

class SpeechToTextBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeechToTextController>(() => SpeechToTextController());
  }
}
