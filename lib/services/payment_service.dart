import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process a simulated payment
  Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
    required String userId,
    Map<String, dynamic>? details,
  }) async {
    // Simulate network delay for payment gateway
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Logic for different payment methods
      bool isSuccess = true;
      String transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      String message = 'Payment successful via $paymentMethod';

      // Simple validation simulation
      if (paymentMethod == 'Credit/Debit Card') {
        if (details?['cardNumber'] == '4444444444444444') {
          isSuccess = false;
          message = 'Card declined by bank';
        }
      }

      final paymentData = {
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'method': paymentMethod,
        'status': isSuccess ? 'completed' : 'failed',
        'timestamp': FieldValue.serverTimestamp(),
        'transactionId': transactionId,
        'details': details,
      };

      // Create a payment record in Firestore
      await _firestore.collection('payments').add(paymentData);

      if (isSuccess) {
        // Update the order status to 'paid'
        await _firestore.collection('orders').doc(orderId).update({
          'paymentStatus': 'paid',
          'transactionId': transactionId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': isSuccess,
        'transactionId': transactionId,
        'message': message,
      };
    } catch (e) {
      debugPrint("Payment Error: $e");
      return {
        'success': false,
        'message': 'Payment failed: ${e.toString()}',
      };
    }
  }

  /// Get payment history for a user
  Stream<QuerySnapshot> getUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
