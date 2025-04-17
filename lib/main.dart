import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';
import 'services/azure_openai_service.dart';
import 'controllers/chat_controller.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  // Initialize dependencies
  final azureOpenAIService = AzureOpenAIService();
  Get.put(azureOpenAIService);
  Get.put(ChatController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    );

    final isLight = brightness == Brightness.light;
    final primary = isLight ? Colors.black : Colors.white;
    final onPrimary = isLight ? Colors.white : Colors.black;

    return baseTheme.copyWith(
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: primary,
        onSecondary: onPrimary,
        error: Colors.red.shade400,
        onError: onPrimary,
        background: isLight ? Colors.white : Colors.black,
        onBackground: primary,
        surface: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
        onSurface: primary,
        errorContainer: isLight ? Colors.red.shade50 : Colors.red.shade900,
        onErrorContainer: isLight ? Colors.red.shade900 : Colors.red.shade50,
      ),
      scaffoldBackgroundColor: isLight ? Colors.white : Colors.black,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: isLight ? Colors.white : Colors.black,
        foregroundColor: primary,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1),
        ),
      ),
      iconTheme: IconThemeData(color: primary),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: primary,
        displayColor: primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Chat Assistant',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}
