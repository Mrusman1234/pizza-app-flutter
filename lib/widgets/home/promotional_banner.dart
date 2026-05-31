import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';

class PromotionalBanner extends StatelessWidget {
  const PromotionalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.restaurants),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0800),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.25)),
              ),
            ),
            const Positioned(
              right: -10, bottom: -10,
              child: Text('🍕', style: TextStyle(fontSize: 90)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
                    child: const Text('LIMITED TIME OFFER',
                        style: TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 0.8)),
                  ),
                  const SizedBox(height: 7),
                  const Text('Buy 1 Get 1\nFREE 🎉',
                      style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w500, height: 1.15)),
                  const SizedBox(height: 5),
                  const Text('On all Large & XL Pizzas today',
                      style: TextStyle(color: AppColors.subtle, fontSize: 11)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Order Now →',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
