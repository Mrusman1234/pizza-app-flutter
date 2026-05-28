import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/order_provider.dart';
import 'providers/deals_provider.dart';
import 'providers/rider_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/commission_provider.dart';
import 'providers/pizza_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'core/constants/app_strings.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';

/// Global key — allows navigation from anywhere (e.g. NotificationService)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Firebase App Check ────────────────────────────────────────────────────
  // On Android/iOS, use the debug provider while in development.
  // For production, swap AndroidProvider.debug → AndroidProvider.playIntegrity
  // and AppleProvider.debug → AppleProvider.deviceCheck (or .appAttest).
  //
  // For web, replace the empty string below with your reCAPTCHA v3 site key
  // from https://console.firebase.google.com → App Check → Web app → Register.
  const recaptchaSiteKey = ''; // ← paste your key here for web builds

  if (kIsWeb) {
    if (recaptchaSiteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(recaptchaSiteKey),
      );
    } else {
      // Web without a key: App Check stays inactive (fine for local dev)
      debugPrint('⚠️  App Check: no reCAPTCHA key set — skipping web activation.');
    }
  } else {
    // Mobile (Android + iOS) — always activate
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  }

  // ── Background messaging ──────────────────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── Local notifications (mobile only) ────────────────────────────────────
  if (!kIsWeb) {
    await NotificationService().init(navigatorKey: navigatorKey);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DealsProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CommissionProvider()),
        ChangeNotifierProvider(create: (_) => PizzaProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: themeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: RouteNames.splash,
      routes: AppRoutes.routes,
    );
  }
}
