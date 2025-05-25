import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/speech_to_text_controller.dart';
import 'chat_screen.dart';
import 'image_generation_screen.dart';
import 'text_to_speech_screen.dart';
import 'speech_to_text_screen.dart';
import 'profile_screen.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Widget> screens = [
      const ChatScreenTabView(),
      const ImageGenerationScreen(),
      const TextToSpeechScreen(),
      const SpeechToTextScreen(),
      const ProfileScreen(),
    ];
    Get.lazyPut<SpeechToTextController>(() => SpeechToTextController());
    return Scaffold(
      body: Obx(() => screens[controller.selectedIndex.value]),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: controller.changeIndex,
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.image),
              label: 'Image Generation',
            ),
            NavigationDestination(
              icon: Icon(Icons.record_voice_over),
              label: 'Text to Speech',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic),
              label: 'Speech to Text',
            ),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
