import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  /// Initiate Stripe Payment Sheet
  Future<bool> startStripePayment({
    required double amount,
    required String checkoutId,
    required String email,
  }) async {
    if (kIsWeb) {
      throw Exception("Stripe Payment Sheet is not supported on Web. Please use mobile app or implement Stripe Checkout for Web.");
    }
    try {
      // 1. Call Cloud Function to create PaymentIntent
      final HttpsCallable callable = _functions.httpsCallable('createStripePayment');
      final response = await callable.call({
        'amount': amount,
        'checkoutId': checkoutId,
        'email': email,
        'currency': 'pkr',
      });

      final clientSecret = response.data['clientSecret'];
      final ephemeralKey = response.data['ephemeralKey'];
      final customerId = response.data['customer'];

      if (clientSecret == null) throw Exception("Failed to initialize payment");

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customerId,
          merchantDisplayName: 'Pizza Hub Vehari',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primary,
            ),
          ),
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return true;
    } catch (e) {
      if (e is StripeException) {
        debugPrint('Stripe Error: ${e.error.localizedMessage}');
        return false;
      }
      debugPrint('Payment Error: $e');
      rethrow;
    }
  }

  /// Initiate JazzCash Payment
  Future<String> initiateJazzCash({
    required double amount,
    required String checkoutId,
  }) async {
    try {
      debugPrint('💳 [JAZZCASH] Initiating payment for Rs $amount (Checkout: $checkoutId)');
      final HttpsCallable callable = _functions.httpsCallable('initiateJazzCashPayment');
      final response = await callable.call({
        'amount': amount,
        'checkoutId': checkoutId,
      });

      final String? html = response.data['html'];
      if (html == null || html.isEmpty) {
        throw Exception("Server returned empty payment HTML");
      }

      debugPrint('✅ [JAZZCASH] Received payment HTML (${html.length} chars)');
      return html;
    } catch (e) {
      debugPrint('❌ [JAZZCASH] Initiation Error: $e');
      rethrow;
    }
  }

  /// Verify JazzCash Transaction
  Future<bool> verifyJazzCash(String transactionId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('verifyJazzCashPaymentStatus');
      final response = await callable.call({
        'transactionId': transactionId,
      });

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('JazzCash Verification Error: $e');
      return false;
    }
  }

  /// Mobile Wallet: JazzCash
  Future<Map<String, dynamic>> payWithJazzCash({
    required String mobileNumber,
    required double amount,
    required String orderId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('payWithJazzCash');
      final response = await callable.call({
        'mobileNumber': mobileNumber,
        'amount': amount,
        'orderId': orderId,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('JazzCash Payment Error: $e');
      return {'initiated': false, 'message': e.toString()};
    }
  }

  /// Mobile Wallet: EasyPaisa
  Future<Map<String, dynamic>> payWithEasyPaisa({
    required String mobileNumber,
    required double amount,
    required String orderId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('payWithEasyPaisa');
      final response = await callable.call({
        'mobileNumber': mobileNumber,
        'amount': amount,
        'orderId': orderId,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('EasyPaisa Payment Error: $e');
      return {'initiated': false, 'message': e.toString()};
    }
  }
}
