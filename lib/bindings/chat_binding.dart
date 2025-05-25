import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../services/azure_openai_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AzureOpenAIService());
    Get.lazyPut<ChatController>(() => ChatController());

  }
}
