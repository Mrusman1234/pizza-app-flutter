import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service for Pizza Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last Updated: June 2024',
              style: TextStyle(color: AppColors.subtle, fontSize: 13),
            ),
            const Divider(height: 40, color: AppColors.border),
            
            _buildSection(
              '1. Terms of Use',
              'By using the Pizza Hub app, you agree to comply with and be bound by these terms. We provide a platform for users to order food from various restaurants in Vehari.',
            ),
            
            _buildSection(
              '2. User Accounts',
              'To use certain features, you must register for an account. You are responsible for maintaining the security of your account and mobile device. You must provide accurate and complete information when creating your account.',
            ),
            
            _buildSection(
              '3. Ordering and Pricing',
              'All orders placed through the app are subject to restaurant availability. Prices listed in the app include applicable taxes unless stated otherwise. Delivery fees are calculated based on the number of restaurants in your order and your distance from them.',
            ),
            
            _buildSection(
              '4. Cancellation and Refunds',
              '• Orders can only be cancelled before the restaurant begins preparation.\n'
              '• If a restaurant is unable to fulfill an order, you will be notified and any online payment will be refunded to your original payment method.\n'
              '• Refunds for cash-on-delivery orders are handled on a case-by-case basis by contacting support.',
            ),
            
            _buildSection(
              '5. Delivery Policy',
              'We aim to deliver your food within the estimated time shown. However, delivery times may be affected by weather, traffic, and restaurant load. Our riders will deliver to the address provided during checkout. Please ensure someone is available to receive the order.',
            ),
            
            _buildSection(
              '6. Payments',
              'We support multiple payment methods including Cash on Delivery, JazzCash, EasyPaisa, and Credit/Debit cards via Stripe. By choosing a payment method, you authorize us to charge the total amount of your order to that account.',
            ),
            
            _buildSection(
              '7. Multi-Restaurant Orders',
              'You may order from multiple restaurants in a single checkout. Please note that such orders may be delivered by different riders and will incur separate delivery fees per restaurant to ensure fresh and timely delivery.',
            ),
            
            _buildSection(
              '8. Prohibited Activities',
              'Users are prohibited from using the app for any fraudulent activities, providing false location data, or harassing riders and restaurant staff.',
            ),
            
            _buildSection(
              '9. Modifications to Terms',
              'We reserve the right to change these terms at any time. Your continued use of the app after such changes constitutes your acceptance of the new terms.',
            ),
            
            _buildSection(
              '10. Contact Support',
              'For any disputes or queries regarding your orders or these terms, please contact us at support@pizzahubvehari.com.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.subtle,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
