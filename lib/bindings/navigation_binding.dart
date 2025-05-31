import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/image_generation_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/text_to_speech_controller.dart';
import '../controllers/video_generation_controller.dart';
import '../services/azure_openai_service.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavigationController());
    Get.put(AzureOpenAIService());
    Get.put(ChatController());
    Get.put(ImageGenerationController());
    Get.put(TextToSpeechController());
    Get.lazyPut<VideoGenerationController>(() => VideoGenerationController());
  }
}
