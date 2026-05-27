import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../routes/route_names.dart';

class AdminSidebar extends StatelessWidget {
  final String activeItem;
  const AdminSidebar({super.key, required this.activeItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_pizza, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pizza O Clock",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    Text("Admin Panel",
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  active: activeItem == 'Dashboard',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminDashboard),
                ),
                _SidebarItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Orders',
                  active: activeItem == 'Orders',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminOrders),
                ),
                _SidebarItem(
                  icon: Icons.store_outlined,
                  label: 'Stores',
                  active: activeItem == 'Stores',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminStores),
                ),
                _SidebarItem(
                  icon: Icons.group_outlined,
                  label: 'Customers',
                  active: activeItem == 'Customers',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminCustomers),
                ),
                _SidebarItem(
                  icon: Icons.delivery_dining_outlined,
                  label: 'Riders',
                  active: activeItem == 'Riders',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminRiders),
                ),
                _SidebarItem(
                  icon: Icons.campaign_outlined,
                  label: 'Promotions',
                  active: activeItem == 'Promotions',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminPromotions),
                ),
                _SidebarItem(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifications',
                  active: activeItem == 'Notifications',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminNotifications),
                ),
                _SidebarItem(
                  icon: Icons.payments_outlined,
                  label: 'Commissions',
                  active: activeItem == 'Commissions',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminCommissions),
                ),
                _SidebarItem(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  active: activeItem == 'Analytics',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminAnalytics),
                ),
                _SidebarItem(
                  icon: Icons.assessment_outlined,
                  label: 'Performance',
                  active: activeItem == 'Performance',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminPerformance),
                ),
                _SidebarItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Store Report',
                  active: activeItem == 'Store Report',
                  onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminRestaurantReport),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            active: activeItem == 'Settings',
            onTap: () => Navigator.pushReplacementNamed(context, RouteNames.adminSettings),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: active ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? AppColors.primary : AppColors.subtle,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.subtle,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
