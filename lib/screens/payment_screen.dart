import 'package:flutter/material.dart';
import '../services/payment_service.dart';

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

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11 || !phone.startsWith('03')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 11-digit mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);

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

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      // Navigate to order confirmation
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.orderSuccess,
          arguments: result['txnRef'],
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${result['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Now')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Total: Rs. ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Select Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _methodTile('jazzcash', 'JazzCash', Colors.red),
              const SizedBox(width: 12),
              _methodTile('easypaisa', 'EasyPaisa', Colors.green),
            ]),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: '03001234567',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pay Rs. ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(String value, String label, Color color) {
    final selected = _selectedMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(10),
            color: selected ? color.withOpacity(0.1) : Colors.white,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: selected ? color : Colors.grey,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
