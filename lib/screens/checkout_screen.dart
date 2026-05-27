import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../routes/route_names.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isPlacingOrder = false;
  Map<String, dynamic>? _selectedAddress;
  String _paymentMethod = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final address = await _firestoreService.getDefaultAddress(user.uid);
      if (mounted) {
        setState(() {
          _selectedAddress = address;
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final restaurantId = cartProvider.restaurantId;
      final restaurantName = cartProvider.restaurantName;
      final promo = cartProvider.appliedPromo;

      final orderId = await _firestoreService.placeOrder(
        userId: user.uid,
        items: cartProvider.items.map((e) => e.toMap()).toList(),
        subtotal: cartProvider.subtotal,
        deliveryFee: cartProvider.deliveryFee,
        tax: cartProvider.tax,
        totalAmount: cartProvider.total,
        discountAmount: cartProvider.discountAmount,
        promoCode: promo?['code'],
        address: _selectedAddress!['address'],
        lat: _selectedAddress!['lat'],
        lng: _selectedAddress!['lng'],
        paymentMethod: _paymentMethod,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      );

      // If promo used, increment redemptions
      if (promo != null && promo['id'] != null) {
        await _firestoreService.incrementPromoRedemption(promo['id']);
      }

      final double totalBeforeClear = cartProvider.total;
      await cartProvider.clearCart();

      if (mounted) {
        if (_paymentMethod == 'JazzCash / EasyPaisa') {
          Navigator.pushReplacementNamed(
            context,
            RouteNames.payment,
            arguments: {
              'amount': totalBeforeClear,
              'orderId': orderId,
            },
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.orderTracking,
            (route) => false,
            arguments: orderId,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
            _buildPaymentOption('Credit/Debit Card', Icons.credit_card, enabled: false),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          opacity: enabled ? 1.0 : 0.5,
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
