import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../routes/route_names.dart';
import 'cart_provider.dart';

class AppAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get user => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isLoggedIn();

  AppAuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    if (isAuthenticated) {
      await fetchUserData(null);
    }
  }

  Future<void> fetchUserData(BuildContext? context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _userModel = UserModel.fromMap(doc.data()!);
          
          // Update FCM Token on successful data fetch
          if (!kIsWeb) {
            NotificationService().updateToken();
          }
          
          if (context != null && context.mounted) {
            final cartProvider = Provider.of<CartProvider>(context, listen: false);
            await cartProvider.loadCartFromFirestore(user.uid);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ── ROLE-BASED NAVIGATION LOGIC ──────────────────────────────────────────
  /// This centralizes redirection after Login or Splash
  void navigateBasedOnRole(BuildContext context) {
    if (_userModel == null) {
      Navigator.pushReplacementNamed(context, RouteNames.login);
      return;
    }

    final String role = _userModel!.role;
    debugPrint('🚦 Routing user with role: $role (Platform: ${kIsWeb ? "Web" : "Mobile"})');

    if (role == 'admin') {
      if (kIsWeb) {
        Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
      } else {
        // Admin on Mobile -> Still allowed to login, but directed to a safe screen
        // or we can block it. User requested "NEVER show Admin UI on mobile".
        // We'll route them to a "Mobile Restricted" view or just Rider Dashboard 
        // if they are Super Admins who also deliver, or just back to Home.
        // For now, let's route to Home but hide Admin links.
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    } else if (role == 'restaurant_admin') {
      // Restaurant admins usually work from Web/Tablet
      if (kIsWeb) {
        Navigator.pushReplacementNamed(context, RouteNames.restaurantAdminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    } else if (role == 'rider') {
      // Riders MUST use mobile
      Navigator.pushReplacementNamed(context, RouteNames.riderDashboard);
    } else {
      // Default: Customers
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }

  Future<bool> login(String email, String password, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.login(email, password);
    if (success && context.mounted) {
      await fetchUserData(context);
      if (_userModel != null) {
        if (_userModel?.role == 'admin') {
          await FirestoreService().initializeDemoData(adminId: _userModel!.uid);
        }
      }
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> signUp(String email, String password, String name, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.signUp(email, password, name);
    if (success && context.mounted) {
      await fetchUserData(context);
      if (_userModel != null) {
        // Initialize demo data if user is admin
        if (_userModel?.role == 'admin') {
          await FirestoreService().initializeDemoData(adminId: _userModel!.uid);
        }
      }
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> googleSignIn(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.signInWithGoogle();
    if (success && context.mounted) {
      await fetchUserData(context);
      if (_userModel != null) {
        // Initialize demo data if user is admin
        if (_userModel?.role == 'admin') {
          await FirestoreService().initializeDemoData(adminId: _userModel!.uid);
        }
      }
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout(BuildContext context) async {
    await _authService.logout();
    _userModel = null;
    if (context.mounted) {
      Provider.of<CartProvider>(context, listen: false).clearLocalCart();
    }
    notifyListeners();
  }

  Future<bool> deleteAccount(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _authService.deleteAccount();
      if (success) {
        _userModel = null;
        if (context.mounted) {
          Provider.of<CartProvider>(context, listen: false).clearLocalCart();
        }
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Show error via SnackBar if context is available
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.sendPasswordResetEmail(email);
    _isLoading = false;
    notifyListeners();
    return success;
  }
}
