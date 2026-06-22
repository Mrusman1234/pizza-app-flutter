import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../core/utils/location_helper.dart';
import '../widgets/custom_button.dart';
import '../routes/route_names.dart';
import 'package:app_multi_restaurant/providers/config_provider.dart';
import '../screens/payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PaymentService _paymentService = PaymentService();
  bool _isPlacingOrder = false;
  Map<String, dynamic>? _selectedAddress;
  String _paymentMethod = 'Cash on Delivery';
  StreamSubscription? _paymentSub;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDefaultAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final address = await _firestoreService.getDefaultAddress(user.uid);
      if (!mounted) return;
      setState(() {
        _selectedAddress = address;
      });
    }
  }

  Future<void> _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final auth = Provider.of<AppAuthProvider>(context, listen: false);

    // ── CONFIG & VALIDATION CHECKS ──────────────────────────────────────
    if (!configProvider.ordersEnabled) {
      _showError('Ordering is currently disabled.');
      return;
    }

    if (cartProvider.subtotal < configProvider.minOrderAmount) {
      _showError('Minimum order amount is Rs. ${configProvider.minOrderAmount.toStringAsFixed(0)}');
      return;
    }

    if (_selectedAddress == null) {
      _showError('Please select a delivery address');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (cartProvider.items.isEmpty) return;

    final userLat = (_selectedAddress?['lat'] as num?)?.toDouble();
    final userLng = (_selectedAddress?['lng'] as num?)?.toDouble();

    // Check restaurants status and distance
    final groups = cartProvider.groups;
    for (var group in groups) {
      final restaurant = await restaurantProvider.getRestaurantById(group.restaurantId);
      if (restaurant == null) continue;
      if (restaurant.isBusy) {
        _showError('${group.restaurantName} is busy.');
        return;
      }
      if (userLat != null && userLng != null && restaurant.latitude != null) {
        final inRange = LocationHelper.isWithinRadius(
          userLat: userLat, userLng: userLng,
          restaurantLat: restaurant.latitude!, restaurantLng: restaurant.longitude!,
          radiusInKm: restaurant.deliveryRadius,
        );
        if (!inRange) {
          _showError('Outside ${group.restaurantName} delivery zone.');
          return;
        }
      }
    }

    setState(() => _isPlacingOrder = true);

    try {
      final userName = auth.user?.name ?? 'Customer';
      final userPhone = auth.user?.phoneNumber ?? '03000000000';
      final checkoutId = FirebaseFirestore.instance.collection('checkouts').doc().id;

      // ── Step 1: Create Order Requests ──
      // For Online payments, they stay as 'PendingPayment'
      // For COD, they become 'Draft' and are processed by Cloud Function immediately
      await _firestoreService.placeOrders(
        userId: user.uid,
        userName: userName,
        userPhone: userPhone,
        cartGroups: groups,
        address: _selectedAddress!['address'],
        lat: _selectedAddress!['lat'],
        lng: _selectedAddress!['lng'],
        paymentMethod: _paymentMethod,
        baseDeliveryFee: configProvider.baseDeliveryFee,
        taxRate: configProvider.taxRate,
        discountAmount: cartProvider.discountAmount,
        promoCode: cartProvider.appliedPromo?['code'],
        checkoutId: checkoutId,
      );

      // ── Step 2: Handle Online Payment ──
      if (_paymentMethod == 'Credit/Debit Card') {
        final paid = await _paymentService.startStripePayment(
          amount: cartProvider.total,
          checkoutId: checkoutId,
          email: user.email ?? '',
        );
        if (!paid) {
          setState(() => _isPlacingOrder = false);
          return;
        }
      } else if (_paymentMethod == 'JazzCash / EasyPaisa') {
        final html = await _paymentService.initiateJazzCash(
          amount: cartProvider.total,
          checkoutId: checkoutId,
        );
        
        if (!mounted) return;

        if (kIsWeb) {
          // On Web, open in new tab to avoid WebView crash and handle redirects better
          final url = Uri.dataFromString(
            html,
            mimeType: 'text/html',
            encoding: utf8,
          ).toString();
          
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          
          // Listen for status in Firestore since we can't 'await' the new tab
          _listenForPaymentStatus(checkoutId);
          return;
        }

        final status = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              htmlContent: html,
              successUrl: 'order-success',
              failureUrl: 'payment-failed',
              title: 'JazzCash Payment',
            ),
          ),
        );

        if (status != 'success') {
          if (mounted) {
            setState(() => _isPlacingOrder = false);
            _showError('Payment cancelled or failed.');
          }
          return;
        }
      }

      // ── Step 3: Cleanup and Success ──
      if (cartProvider.appliedPromo != null) {
        await _firestoreService.incrementPromoRedemption(cartProvider.appliedPromo!['id']);
      }

      await cartProvider.clearCart();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.orderSuccess,
          (route) => false,
          arguments: checkoutId,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showError('Order Error: $e');
      }
    }
  }

  void _listenForPaymentStatus(String checkoutId) {
    _paymentSub?.cancel();
    _paymentSub = FirebaseFirestore.instance
        .collection('checkouts')
        .doc(checkoutId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;
      if (snapshot.exists) {
        final status = snapshot.data()?['status'];
        if (status == 'paid') {
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          
          if (cartProvider.appliedPromo != null) {
            await _firestoreService.incrementPromoRedemption(cartProvider.appliedPromo!['id']);
          }

          await cartProvider.clearCart();

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.orderSuccess,
              (route) => false,
              arguments: snapshot.data()?['txnRef'] ?? checkoutId,
            );
          }
        } else if (status == 'failed') {
          setState(() => _isPlacingOrder = false);
          _showError('Payment Failed: ${snapshot.data()?['error'] ?? "Transaction declined"}');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Delivery Address'),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentOption('Cash on Delivery', Icons.money),
            _buildPaymentOption('JazzCash / EasyPaisa', Icons.account_balance_wallet),
            _buildPaymentOption('Credit/Debit Card', Icons.credit_card),
            const SizedBox(height: 32),
            _buildSectionTitle('Order Summary'),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', cartProvider.subtotal),
            if (cartProvider.discountAmount > 0)
              _buildSummaryRow(
                'Discount ${cartProvider.appliedPromo != null ? "(${cartProvider.appliedPromo!['code']})" : ""}', 
                cartProvider.discountAmount, 
                isDiscount: true
              ),
            _buildSummaryRow('Delivery Fee', cartProvider.deliveryFee),
            _buildSummaryRow('Tax', cartProvider.tax),
            const Divider(color: AppColors.border, height: 32),
            _buildSummaryRow('Total', cartProvider.total, isTotal: true),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Place Order',
              isLoading: _isPlacingOrder,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAddress?['type'] ?? 'Select Address',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  _selectedAddress?['address'] ?? 'No address selected',
                  style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, RouteNames.addressManagement);
              if (result != null && result is Map<String, dynamic>) {
                setState(() => _selectedAddress = result);
              } else {
                _loadDefaultAddress();
              }
            },
            child: const Text('Change', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, {bool enabled = true}) {
    final isSelected = _paymentMethod == method;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _paymentMethod = method) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.subtle),
              const SizedBox(width: 16),
              Text(
                method,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.subtle,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : AppColors.subtle,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? "- " : ""}Rs ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isDiscount ? AppColors.green : (isTotal ? AppColors.primary : Colors.white),
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
