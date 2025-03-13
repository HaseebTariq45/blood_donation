import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants/app_constants.dart';
import 'providers/app_provider.dart';
import 'services/network_tracker_service.dart';
import 'services/service_locator.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/donor_search_screen.dart';
import 'screens/blood_request_screen.dart';
import 'screens/blood_requests_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/blood_banks_screen.dart';
import 'screens/donation_history_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/data_usage_screen.dart';
import 'utils/localization/app_localization.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables but don't halt execution if file is missing
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    // Continue execution despite the error
  }
  
  // Create the app provider
  final appProvider = AppProvider();
  
  // Initialize services
  serviceLocator.initialize(appProvider);
  
  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    
    // Determine if the current language requires right-to-left layout
    final isRtl = appProvider.locale.languageCode == 'ar' || appProvider.locale.languageCode == 'ur';
    
    return MaterialApp(
      title: 'Blood Donation App',
      debugShowCheckedModeBanner: false,
      
      // Localization support
      locale: appProvider.locale,
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
        Locale('fr', 'FR'), // French
        Locale('ar', 'SA'), // Arabic
        Locale('ur', 'PK'), // Urdu
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Set text direction based on language
      builder: (context, child) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      
      theme: AppConstants.getThemeData(),
      darkTheme: AppConstants.getDarkThemeData(),
      themeMode: appProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/donor_search': (context) => const DonorSearchScreen(),
        '/blood_request': (context) => const BloodRequestScreen(),
        '/blood_requests_list': (context) => const BloodRequestsListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/notification_settings': (context) => const NotificationSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/blood_banks': (context) => const BloodBanksScreen(),
        '/donation_history': (context) => const DonationHistoryScreen(),
        '/about_us': (context) => const AboutUsScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/terms_conditions': (context) => const TermsConditionsScreen(),
        '/data_usage': (context) => const DataUsageScreen(),
      },
    );
  }
}
