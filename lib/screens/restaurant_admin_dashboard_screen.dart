import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_admin_provider.dart';
import '../routes/route_names.dart';
import '../models/restaurant_admin_model.dart';
import '../core/constants/firestore_constants.dart';
import 'package:app_multi_restaurant/providers/config_provider.dart';

class RestaurantAdminDashboardScreen extends StatefulWidget {
  const RestaurantAdminDashboardScreen({super.key});

  @override
  State<RestaurantAdminDashboardScreen> createState() =>
      _RestaurantAdminDashboardScreenState();
}

class _RestaurantAdminDashboardScreenState
    extends State<RestaurantAdminDashboardScreen> {
  bool _showRevenueChart = true;
  int _lastPendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      final uid = auth.user?.uid;
      if (uid != null) {
        context.read<RestaurantAdminProvider>().loadAdmin(uid);
      }
    });
  }

  Future<void> _logout() async {
    final authProvider = context.read<AppAuthProvider>();
    context.read<RestaurantAdminProvider>().clear();
    await authProvider.logout(context);
    if (mounted) Navigator.pushReplacementNamed(context, RouteNames.adminLogin);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantAdminProvider>();

    // ── NEW ORDER ALERT LOGIC ──────────────────────────────────
    if (provider.pendingOrdersCount > _lastPendingCount) {
      _lastPendingCount = provider.pendingOrdersCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewOrderAlert();
      });
    } else {
      _lastPendingCount = provider.pendingOrdersCount;
    }

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final admin = provider.adminModel;
    if (admin == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Unable to load admin data.',
              style: TextStyle(color: AppColors.text)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(admin.name, admin.assignedRestaurantName),
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.refresh,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatsGrid(provider),
                    const SizedBox(height: 20),
                    _buildChartSection(provider),
                    const SizedBox(height: 20),
                    _buildTopSellingItems(provider),
                    const SizedBox(height: 20),
                    _buildQuickActions(admin),
                    const SizedBox(height: 20),
                    _buildRecentOrders(provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewOrderAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.notification_important, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔥 NEW ORDER ALERT! Check your pending orders immediately.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, RouteNames.restaurantAdminOrders),
        ),
      ),
    );
  }

  Widget _buildHeader(String adminName, String restaurantName) {
    final configProvider = Provider.of<ConfigProvider>(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${configProvider.appName} Admin: $adminName',
                      style: const TextStyle(color: AppColors.subtle, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Access-level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Restaurant Admin',
                  style: TextStyle(
                      color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _logout,
                child: const Icon(Icons.logout_rounded, color: AppColors.subtle, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBusyModeToggle(),
        ],
      ),
    );
  }

  Widget _buildBusyModeToggle() {
    final provider = context.watch<RestaurantAdminProvider>();
    final restId = provider.restaurantId;

    if (restId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: provider.restaurantStream(restId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final bool isBusy = data?['isBusy'] ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isBusy ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isBusy ? Colors.redAccent.withValues(alpha: 0.3) : AppColors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isBusy ? Icons.notifications_paused_rounded : Icons.check_circle_rounded,
                color: isBusy ? Colors.redAccent : AppColors.green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBusy ? 'Busy Mode Active' : 'Accepting Orders',
                      style: TextStyle(
                        color: isBusy ? Colors.redAccent : AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isBusy ? 'New orders are temporarily disabled' : 'Customers can place orders normally',
                      style: TextStyle(
                        color: (isBusy ? Colors.redAccent : AppColors.green).withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isBusy,
                onChanged: (val) async {
                  await FirebaseFirestore.instance.collection(FirestoreConstants.restaurants).doc(restId).update({
                    'isBusy': val,
                  });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Restaurant is now in Busy Mode' : 'Restaurant is now accepting orders'),
                      backgroundColor: val ? Colors.redAccent : AppColors.green,
                    ),
                  );
                },
                activeThumbColor: Colors.redAccent,
                activeTrackColor: Colors.redAccent.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.green,
                inactiveTrackColor: AppColors.green.withValues(alpha: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(RestaurantAdminProvider p) {
    final stats = [
      _StatItem("Today's Orders", p.todayOrdersCount.toString(),
          Icons.receipt_long_rounded, AppColors.primary),
      _StatItem("Today's Revenue",
          'Rs ${p.todayRevenue.toStringAsFixed(0)}',
          Icons.payments_rounded, AppColors.green),
      _StatItem('Pending', p.pendingOrdersCount.toString(),
          Icons.pending_actions_rounded, AppColors.amber),
      _StatItem('Menu Items', p.menuItemCount.toString(),
          Icons.restaurant_menu_rounded, Colors.blueAccent),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(stat.value,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              Text(stat.label,
                  style: const TextStyle(
                      color: AppColors.subtle, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(RestaurantAdminProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_showRevenueChart ? 'Revenue Trend (7D)' : 'Order Trend (7D)',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Row(
                children: [
                  _chartToggle('Rev', _showRevenueChart, () => setState(() => _showRevenueChart = true)),
                  const SizedBox(width: 8),
                  _chartToggle('Ord', !_showRevenueChart, () => setState(() => _showRevenueChart = false)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        int idx = val.toInt();
                        if (idx < 0 || idx >= p.trendLabels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(p.trendLabels[idx],
                              style: const TextStyle(color: AppColors.subtle, fontSize: 9)),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _showRevenueChart
                        ? p.revenueTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
                        : p.orderTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                    isCurved: true,
                    color: _showRevenueChart ? AppColors.green : AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (_showRevenueChart ? AppColors.green : AppColors.primary).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.primary : AppColors.subtle,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTopSellingItems(RestaurantAdminProvider provider) {
    if (provider.topSellingItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling Items',
              style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...provider.topSellingItems.map((item) {
            final double percentage = provider.topSellingItems.first['count'] > 0 
                ? item['count'] / provider.topSellingItems.first['count'] 
                : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                      Text('${item['count']} sold', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActions(RestaurantAdminModel admin) {
    final actions = [
      if (admin.canManageOrders)
        _ActionItem('Manage Orders', Icons.receipt_long_rounded, AppColors.primary,
            RouteNames.restaurantAdminOrders),
      if (admin.canManageMenu)
        _ActionItem('Manage Menu', Icons.restaurant_menu_rounded, AppColors.green,
            RouteNames.restaurantAdminMenu),
      _ActionItem('Wallet', Icons.account_balance_wallet_rounded, Colors.orange,
            RouteNames.wallet),
      if (admin.canViewStats)
        _ActionItem('Audit Logs', Icons.history_rounded, AppColors.subtle,
            RouteNames.restaurantAdminAuditLogs),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: actions
              .map((a) => Expanded(child: _buildActionButton(a)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(_ActionItem action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, action.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Icon(action.icon, color: action.color, size: 24),
              const SizedBox(height: 6),
              Text(action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders(RestaurantAdminProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Orders',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, RouteNames.restaurantAdminOrders),
              child: const Text('View all',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: provider.ordersStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState('Error loading orders: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primary),
              ));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Center(
                  child: Text('No orders yet today',
                      style: TextStyle(color: AppColors.subtle)),
                ),
              );
            }
            final preview = docs.take(5).toList();
            return Column(
              children: preview
                  .map((doc) => _buildOrderTile(doc.data(), doc.id))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order, String orderId) {
    final status = order[FirestoreConstants.status] as String? ?? FirestoreConstants.statusPending;
    final statusColor = _statusColor(status);
    final total = (order[FirestoreConstants.totalAmount] as num?)?.toDouble() ?? 0;
    final customer = order[FirestoreConstants.userName] as String? ?? 'Customer';
    final createdAt = order[FirestoreConstants.createdAt];
    String timeStr = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: statusColor),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text('#${orderId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                        color: AppColors.subtle, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(timeStr,
                style:
                    const TextStyle(color: AppColors.subtle, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case FirestoreConstants.statusPending:    return AppColors.amber;
      case FirestoreConstants.statusPreparing:  return Colors.blueAccent;
      case FirestoreConstants.statusOnTheWay: return Colors.purpleAccent;
      case FirestoreConstants.statusDelivered:  return AppColors.green;
      case FirestoreConstants.statusCancelled:  return Colors.redAccent;
      default:           return AppColors.subtle;
    }
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _ActionItem {
  final String label, route;
  final IconData icon;
  final Color color;
  const _ActionItem(this.label, this.icon, this.color, this.route);
}
