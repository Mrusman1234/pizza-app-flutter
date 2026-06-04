import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class RestaurantShimmer extends StatelessWidget {
  const RestaurantShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(width: double.infinity, height: 160, borderRadius: 16),
          const SizedBox(height: 12),
          const ShimmerLoader(width: 200, height: 20),
          const SizedBox(height: 8),
          const ShimmerLoader(width: 150, height: 14),
        ],
      ),
    );
  }
}

class MenuItemShimmer extends StatelessWidget {
  const MenuItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const ShimmerLoader(width: 80, height: 80, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoader(width: 150, height: 16),
                SizedBox(height: 8),
                ShimmerLoader(width: 200, height: 12),
                SizedBox(height: 12),
                ShimmerLoader(width: 60, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
