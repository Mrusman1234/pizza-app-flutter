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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Acceptance of Terms',
              'By accessing or using our application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              'Orders and Payments',
              'You are responsible for providing accurate information when placing an order. All payments are processed securely. In case of disputes, please contact our support team.',
            ),
            _buildSection(
              'Delivery',
              'Delivery times are estimates and may vary based on weather, traffic, and restaurant preparation times. Our riders strive to deliver your orders promptly within the designated zones in Vehari.',
            ),
            _buildSection(
              'Account Responsibility',
              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
            ),
            _buildSection(
              'Modification of Services',
              'We reserve the right to modify or discontinue any part of our service at any time without prior notice.',
            ),
            _buildSection(
              'Limitation of Liability',
              'We shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use our services.',
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
