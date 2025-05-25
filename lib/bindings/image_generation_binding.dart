import 'package:get/get.dart';
import '../controllers/image_generation_controller.dart';

class ImageGenerationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ImageGenerationController());
  }
}
