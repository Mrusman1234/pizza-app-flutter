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
              'Privacy Policy for Pizza Hub Vehari',
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
              '1. Introduction',
              'Welcome to Pizza Hub Vehari. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.',
            ),
            
            _buildSection(
              '2. The Data We Collect',
              'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:\n\n'
              '• Identity Data: includes first name, last name, username or similar identifier.\n'
              '• Contact Data: includes delivery address, email address and telephone numbers.\n'
              '• Technical Data: includes internet protocol (IP) address, your login data, browser type and version, time zone setting and location, browser plug-in types and versions, operating system and platform.\n'
              '• Usage Data: includes information about how you use our app and services.\n'
              '• Marketing Data: includes your preferences in receiving marketing from us.',
            ),
            
            _buildSection(
              '3. Location Data',
              'We use location services to provide a better experience. We collect your precise or approximate location information:\n\n'
              '• For Customers: To help you find restaurants near you and to track your order in real-time.\n'
              '• For Riders: To facilitate order assignment and navigation. This may be collected even when the app is in the background if you are active as a rider.',
            ),
            
            _buildSection(
              '4. Payment Information',
              'Payment processing is handled by third-party providers (Stripe, JazzCash, EasyPaisa). We do not store your full credit card details or wallet PINs on our servers. We only store transaction references provided by these services to verify payment status.',
            ),
            
            _buildSection(
              '5. How We Use Your Data',
              'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n'
              '• To register you as a new customer or rider.\n'
              '• To process and deliver your order including managing payments, fees and charges.\n'
              '• To manage our relationship with you.\n'
              '• To use data analytics to improve our app, services, and customer experiences.',
            ),
            
            _buildSection(
              '6. Data Security',
              'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. We limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.',
            ),
            
            _buildSection(
              '7. Your Legal Rights',
              'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to request access, correction, erasure, or restriction of your personal data. You also have the right to deactivate your account at any time via the Settings menu.',
            ),
            
            _buildSection(
              '8. Contact Us',
              'If you have any questions about this privacy policy or our privacy practices, please contact us at:\n\n'
              'Email: support@pizzahubvehari.com\n'
              'WhatsApp: +92 300 0000000',
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
