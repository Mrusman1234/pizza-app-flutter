import 'package:flutter/material.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../core/constants/app_strings.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startLoading();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    debugPrint("Splash: Reached 100%, checking login status...");
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      if (!mounted) return;
      
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final bool loggedIn = authProvider.isAuthenticated;

      if (mounted) {
        if (loggedIn) {
          debugPrint("Splash: User is logged in. Fetching user data...");
          await authProvider.fetchUserData(context);
          
          if (!mounted) return;
          
          final user = authProvider.user;
          if (user != null) {
            // Initialize demo data for admin if needed
            if (user.role == 'admin') {
              await FirestoreService().initializeDemoData(adminId: user.uid);
            }

            debugPrint("Splash: User role is ${user.role}. Navigating...");
            if (user.role == 'admin') {
              Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
            } else if (user.role == 'rider') {
              Navigator.pushReplacementNamed(context, RouteNames.riderDashboard);
            } else {
              Navigator.pushReplacementNamed(context, RouteNames.home);
            }
          } else {
            debugPrint("Splash: No user data found. Navigating to Home...");
            Navigator.pushReplacementNamed(context, RouteNames.home);
          }
        } else {
          debugPrint("Splash: No user found. Navigating to Login...");
          Navigator.pushReplacementNamed(context, RouteNames.login);
        }
      }
    } catch (e) {
      debugPrint("Splash Error: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.login);
      }
    }
  }

  void startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (mounted) {
        setState(() {
          progress += 0.02;
          if (progress >= 1.0) {
            progress = 1.0;
            timer.cancel();
            _checkLoginStatus();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int percent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFD3122F),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: GridView.count(
                crossAxisCount: 4,
                children: const [
                  Icon(Icons.local_pizza, size: 120, color: Colors.white),
                  Icon(Icons.restaurant, size: 100, color: Colors.white),
                  Icon(Icons.local_pizza, size: 140, color: Colors.white),
                  Icon(Icons.menu_book, size: 110, color: Colors.white),
                  Icon(Icons.delivery_dining, size: 130, color: Colors.white),
                  Icon(Icons.shopping_basket, size: 90, color: Colors.white),
                  Icon(Icons.local_pizza, size: 150, color: Colors.white),
                  Icon(Icons.lunch_dining, size: 120, color: Colors.white),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black26,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.local_pizza,
                    size: 70,
                    color: Color(0xFFD3122F),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    "VEHARI",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "All Pizza Houses of Vehari in One App",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Loading flavors...",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "$percent%",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "PREMIUM DELIVERY EXPERIENCE",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


