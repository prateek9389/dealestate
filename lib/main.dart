import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/firebase_initializer.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment configs
  await dotenv.load(fileName: ".env");

  // Initialize Firebase and Cloud Messaging
  await FirebaseInitializer.init();
  await NotificationService().initializeFCM();

  // Initialize theme from SharedPreferences
  await AppTheme.init();

  runApp(const DealEstateApp());
}

class DealEstateApp extends StatelessWidget {
  const DealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp.router(
          title: 'DealEstate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
