import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Information We Collect',
              'We collect information you provide directly to us, such as when you create or modify your account, place an order, contact customer support, or otherwise communicate with us. This information may include: name, email, phone number, delivery address, payment method details, and order details.',
            ),
            _buildSection(
              'Location Information',
              'To facilitate order delivery, we collect precise location data of riders. For customers, we collect location data to help you find nearby restaurants and to allow you to track your delivery on a map.',
            ),
            _buildSection(
              'How We Use Information',
              'We use the information we collect to: Provide, maintain, and improve our services; process and deliver orders; send related information, including confirmations and invoices; and respond to your comments and questions.',
            ),
            _buildSection(
              'Sharing of Information',
              'We may share your information with restaurants to process your orders and with riders to facilitate deliveries. We do not sell your personal information to third parties.',
            ),
            _buildSection(
              'Security',
              'We use appropriate security measures to protect your information from unauthorized access, alteration, or destruction.',
            ),
            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact our support team in Vehari.',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Last Updated: May 2024',
                style: TextStyle(color: AppColors.subtle, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
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
