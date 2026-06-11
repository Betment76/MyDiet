import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_diet/screens/disclaimer_screen.dart';
import 'package:my_diet/screens/home_screen.dart';
import 'package:my_diet/screens/onboarding_screen.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/disclaimer_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/services/notification_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/purchase_verification_service.dart';
import 'package:my_diet/services/rustore_review_service.dart';
import 'package:my_diet/services/yandex_ads_service.dart';
import 'package:my_diet/utils/ad_free_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Чёрный системный бар
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
  ));

  await YandexAdsService().initialize();
  await AdFreeNotifier.refreshFromPrefs();
  await NotificationService().init();
  await NotificationService().rescheduleFromSavedSettings();
  await PurchaseVerificationService.verifyAndSyncPurchases();
  await RustoreReviewService.initialize();

  // Проверяем дисклеймер и профиль
  final disclaimerAccepted = await DisclaimerService.isAccepted();
  if (disclaimerAccepted) {
    await AppMetricaService.initialize();
  }
  final profileExists = await ProfileService.exists();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyDietApp(
        disclaimerAccepted: disclaimerAccepted,
        profileExists: profileExists,
      ),
    ),
  );
}

class MyDietApp extends StatefulWidget {
  final bool disclaimerAccepted;
  final bool profileExists;

  const MyDietApp({
    super.key,
    required this.disclaimerAccepted,
    required this.profileExists,
  });

  @override
  State<MyDietApp> createState() => _MyDietAppState();
}

class _MyDietAppState extends State<MyDietApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().rescheduleFromSavedSettings();
      PurchaseVerificationService.verifyAndSyncPurchases().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  String get _initialRoute {
    if (!widget.disclaimerAccepted) return '/disclaimer';
    if (widget.profileExists) return '/home';
    return '/onboarding';
  }

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
        initialRoute: _initialRoute,
        routes: {
          '/disclaimer': (_) => const DisclaimerScreen(),
          '/home': (_) => const HomeScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
        },
      ),
    );
  }
}
