import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/order_provider.dart';
import 'providers/deals_provider.dart';
import 'providers/rider_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/commission_provider.dart';
import 'providers/pizza_provider.dart';
import 'providers/restaurant_admin_provider.dart';
import 'providers/wallet_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/restaurant_admin_service.dart';
import 'package:app_multi_restaurant/providers/config_provider.dart';
import 'screens/maintenance_screen.dart';

/// Global key — allows navigation from anywhere (e.g. NotificationService)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Crashlytics & Performance ─────────────────────────────────────────────
  if (!kIsWeb) {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable Performance Monitoring
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }

  // ✅ Stability fix for Firestore Web: Ensure persistence and handle transport errors
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  if (!kIsWeb) {
    try {
      Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
      await Stripe.instance.applySettings();
      debugPrint('✅ Stripe initialized successfully');
    } catch (e) {
      debugPrint('❌ Stripe initialization failed: $e');
    }
  }
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Crashlytics & Performance ─────────────────────────────────────────────
  if (!kIsWeb) {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable Performance Monitoring
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }

  // ✅ Stability fix for Firestore Web: Ensure persistence and handle transport errors
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  if (!kIsWeb) {
    try {
      Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
      await Stripe.instance.applySettings();
      debugPrint('✅ Stripe initialized successfully');
    } catch (e) {
      debugPrint('❌ Stripe initialization failed: $e');
    }
  }

  // ── Firebase App Check ────────────────────────────────────────────────────
  // On Android/iOS, use the debug provider while in development.
  // For production, swap AndroidProvider.debug → AndroidProvider.playIntegrity
  // and AppleProvider.debug → AppleProvider.deviceCheck (or .appAttest).
  //
  // For web, replace the empty string below with your reCAPTCHA v3 site key
  // from https://console.firebase.google.com → App Check → Web app → Register.
  final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'] ?? '';

  if (kIsWeb) {
    if (recaptchaSiteKey.isNotEmpty) {
      try {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(recaptchaSiteKey),
        );
      } catch (e) {
        debugPrint('⚠️  App Check: activation failed: $e');
      }
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
        Provider(create: (_) => RestaurantAdminService()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProxyProvider<ConfigProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, config, cart) => cart!..updateConfig(config),
        ),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DealsProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CommissionProvider()),
        ChangeNotifierProvider(create: (_) => PizzaProvider()),
        ChangeNotifierProvider(
          create: (context) => RestaurantAdminProvider(
            context.read<RestaurantAdminService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
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
    final configProvider = Provider.of<ConfigProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: configProvider.appName,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: themeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: RouteNames.splash,
      routes: AppRoutes.routes,
      builder: (context, child) {
        final config = Provider.of<ConfigProvider>(context);
        final auth = Provider.of<AppAuthProvider>(context);

        if (config.maintenanceMode && auth.user?.role != 'admin') {
          return const MaintenanceScreen();
        }

        return child!;
      },
    );
  }
}
