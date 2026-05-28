import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../routes/route_names.dart';
import '../core/constants/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  const PaymentScreen({super.key, required this.amount, required this.orderId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  String _selectedMethod = 'jazzcash'; // or 'easypaisa'
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11 || !phone.startsWith('03')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 11-digit mobile number'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;
      if (_selectedMethod == 'jazzcash') {
        result = await PaymentService.payWithJazzCash(
          mobileNumber: phone,
          amount: widget.amount,
          orderId: widget.orderId,
        );
      } else {
        result = await PaymentService.payWithEasyPaisa(
          mobileNumber: phone,
          amount: widget.amount,
          orderId: widget.orderId,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.orderSuccess,
          arguments: result['txnRef'],
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result['message']}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(color: AppColors.subtle, fontSize: 16),
                  ),
                  Text(
                    'Rs. ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _methodTile('jazzcash', 'JazzCash', Colors.redAccent, 'assets/logos/jazzcash.png'),
                const SizedBox(width: 16),
                _methodTile('easypaisa', 'EasyPaisa', AppColors.green, 'assets/logos/easypaisa.png'),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Account Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                labelStyle: const TextStyle(color: AppColors.subtle),
                hintText: '03001234567',
                hintStyle: TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.card,
                counterStyle: const TextStyle(color: AppColors.subtle),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                prefixIcon: const Icon(Icons.phone_iphone, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirm Payment',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Secure SSL Encrypted Payment',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(String value, String label, Color color, String assetPath) {
    final selected = _selectedMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : AppColors.card,
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                value == 'jazzcash' ? Icons.account_balance_wallet : Icons.payments,
                color: selected ? color : AppColors.muted,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.subtle,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
