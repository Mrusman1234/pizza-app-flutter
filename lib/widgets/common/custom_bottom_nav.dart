import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushNamedAndRemoveUntil(context, RouteNames.home, (route) => false);
                  }
                },
              ),
              _navItem(
                context,
                icon: Icons.storefront_rounded,
                label: 'Hubs',
                index: 1,
                onTap: () {
                  if (currentIndex != 1) {
                    Navigator.pushNamed(context, RouteNames.restaurants);
                  }
                },
              ),
              // Cart FAB
              _buildCartFab(context),
              _navItem(
                context,
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                index: 3,
                onTap: () {
                  if (currentIndex != 3) {
                    Navigator.pushNamed(context, RouteNames.myOrders);
                  }
                },
              ),
              _navItem(
                context,
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
                onTap: () {
                  if (currentIndex != 4) {
                    Navigator.pushNamed(context, RouteNames.profile);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartFab(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.cart),
      child: Transform.translate(
        offset: const Offset(0, -15),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.itemCount == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        cart.itemCount.toString(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required int index, required VoidCallback onTap}) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.muted;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
