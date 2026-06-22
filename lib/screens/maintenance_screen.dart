import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              const Text(
                'Under Maintenance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We are currently performing scheduled maintenance to improve our services. We\'ll be back online shortly!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subtle,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 40),
              Text(
                'Thanks for your patience!',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
