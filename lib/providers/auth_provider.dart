import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
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
    // Note: We don't pass context here as it's not available during provider initialization.
    // SplashScreen will handle the initial cart loading via fetchUserData(context).
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
          
          // Load cart if context is provided (e.g. during auto-login)
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

  Future<bool> login(String email, String password, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.login(email, password);
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

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    final success = await _authService.sendPasswordResetEmail(email);
    _isLoading = false;
    notifyListeners();
    return success;
  }
}
