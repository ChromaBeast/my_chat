import 'package:get/get.dart';
import '../controllers/video_generation_controller.dart';

class VideoGenerationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoGenerationController>(() => VideoGenerationController());
  }
}
