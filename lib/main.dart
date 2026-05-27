import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications
  if (!kIsWeb) {
    await NotificationService().init();
  }

  // Initialize Demo Data (Optional: Seed Firestore with restaurants and deals)
  // await FirestoreService().initializeDemoData();

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
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: lightTheme,      // light mode theme
      darkTheme: darkTheme,   // dark mode theme
      locale: themeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: RouteNames.splash,
      routes: AppRoutes.routes,
    );
  }
}
