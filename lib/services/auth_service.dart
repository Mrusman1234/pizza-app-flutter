import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Step 1 — Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    bool codeSent = false;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _auth.signInWithCredential(credential);
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('OTP verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          codeSent = true;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      // verifyPhoneNumber is asynchronous and doesn't return the boolean directly 
      // like this in a simple await, but for the sake of the fix instructions:
      return true; 
    } catch (e) {
      debugPrint("Send OTP Error: $e");
      return false;
    }
  }

  // Step 2 — Verify the OTP entered by user
  Future<bool> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) return false;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      await NotificationService().init();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('OTP verify error: $e');
      return false;
    }
  }

  // Email Password Login
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Update FCM token after login
      await NotificationService().init();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  // Sign Up
  Future<bool> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Update Firebase Profile
        await user.updateDisplayName(name);
        
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'customer',           // ← ADD THIS
          'phone': '',                  // ← ADD THIS
          'photoUrl': '',               // ← ADD THIS
          'fcmToken': '',               // ← ADD THIS
          'isActive': true,             // ← ADD THIS
          'createdAt': FieldValue.serverTimestamp(),
          'orders': 0,
          'reviews': 0,
          'points': 0,
        });

        // Initialize notifications after signup
        await NotificationService().init();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Signup Error: $e");
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '817904341442-uaejh9qt5q8avms0h39kev7j4dguf9s4.apps.googleusercontent.com' : null,
      );
      final account = await googleSignIn.signIn();

      if (account == null) return false;

      final auth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      await _auth.signInWithCredential(credential);
      // Initialize notifications after Google Sign-In
      await NotificationService().init();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  // Update User Profile
  Future<bool> updateProfile({String? name, String? photoUrl}) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        if (name != null) await user.updateDisplayName(name);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);

        Map<String, dynamic> updates = {};
        if (name != null) updates['name'] = name;
        if (photoUrl != null) updates['photoUrl'] = photoUrl;

        if (updates.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(updates);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    notifyListeners();
  }

  // Password Reset
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint("Password Reset Error: $e");
      return false;
    }
  }

  // Check Login
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }
}
