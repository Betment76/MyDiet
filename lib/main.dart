import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_diet/screens/home_screen.dart';
import 'package:my_diet/screens/onboarding_screen.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/services/notification_service.dart';
import 'package:my_diet/services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Чёрный системный бар
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
  ));

  await NotificationService().init();

  // Проверяем, заполнен ли профиль
  final profileExists = await ProfileService.exists();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyDietApp(profileExists: profileExists),
    ),
  );
}

class MyDietApp extends StatelessWidget {
  final bool profileExists;

  const MyDietApp({super.key, required this.profileExists});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: 'Моя диета',
        debugShowCheckedModeBanner: false,
        theme: themeProvider.theme,
        initialRoute: profileExists ? '/home' : '/onboarding',
        routes: {
          '/home': (_) => const HomeScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
        },
      ),
    );
  }
}
