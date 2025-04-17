import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../widgets/nav_bar.dart';
import 'chat_screen.dart';
import 'image_generation_screen.dart';

class HomeScreen extends GetView<NavigationController> {
  HomeScreen({super.key}) {
    Get.put(NavigationController());
  }

  final List<Widget> _pages = const [
    ChatScreen(),
    ImageGenerationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => _pages[controller.selectedIndex],
      ),
      bottomNavigationBar: Obx(
        () => NavBar(
          selectedIndex: controller.selectedIndex,
          onItemSelected: controller.changePage,
        ),
      ),
    );
  }
}
