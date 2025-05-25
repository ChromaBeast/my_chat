import 'package:get/get.dart';
import 'bindings/chat_binding.dart';
import 'bindings/image_generation_binding.dart';
import 'bindings/navigation_binding.dart';
import 'bindings/profile_binding.dart';
import 'bindings/speech_to_text_binding.dart';
import 'bindings/text_to_speech_binding.dart';
import 'routes.dart';
import 'screens/chat_screen.dart';
import 'screens/image_generation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/navigation_screen.dart';

import 'screens/profile_screen.dart';
import 'screens/speech_to_text_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/text_to_speech_screen.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.navigation,
      page: () => const NavigationScreen(),
      binding: NavigationBinding(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreenTabView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.imageGen,
      page: () => const ImageGenerationScreen(),
      binding: ImageGenerationBinding(),
    ),
    GetPage(
      name: AppRoutes.tts,
      page: () => const TextToSpeechScreen(),
      binding: TextToSpeechBinding(),
    ),
    GetPage(
      name: AppRoutes.stt,
      page: () => const SpeechToTextScreen(),
      binding: SpeechToTextBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
  ];
}
