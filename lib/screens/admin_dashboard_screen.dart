import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_sidebar.dart';
import '../../routes/route_names.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Selection
  String? selectedRestaurantId;
  List<Map<String, dynamic>> restaurantsList = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final String? currentAdminId = FirebaseAuth.instance.currentUser?.uid;
    if (currentAdminId == null) return;

    _firestoreService.getRestaurants(adminId: currentAdminId).listen((data) {
      if (mounted) {
        setState(() {
          restaurantsList = data.map((r) => {
            'id': r[FirestoreConstants.id],
            'name': r[FirestoreConstants.name] ?? 'Unknown',
          }).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? currentAdminId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeItem: 'Dashboard'),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _firestoreService.getDashboardStats(
                adminId: currentAdminId,
                restaurantId: selectedRestaurantId,
              ),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                final int totalOrders = stats[FirestoreConstants.totalOrders] ?? 0;
                final double totalRevenue = (stats[FirestoreConstants.totalRevenue] ?? 0.0).toDouble();
                final double totalCommission = (stats[FirestoreConstants.totalCommission] ?? 0.0).toDouble();
                final int totalRestaurants = stats[FirestoreConstants.totalRestaurants] ?? 0;
                final int totalCustomers = stats[FirestoreConstants.totalCustomers] ?? 0;
                final int totalRiders = stats[FirestoreConstants.totalRiders] ?? 0;
                final int pendingOrders = stats[FirestoreConstants.pendingOrders] ?? 0;

                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dashboard Overview',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: selectedRestaurantId,
                                  hint: const Text('All Restaurants', style: TextStyle(color: AppColors.subtle, fontSize: 13)),
                                  dropdownColor: AppColors.card,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16),
                                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  items: [
                                    const DropdownMenuItem<String?>(value: null, child: Text('Global View')),
                                    ...restaurantsList.map((r) => DropdownMenuItem<String?>(value: r['id'], child: Text(r['name']))),
                                  ],
                                  onChanged: (val) {
                                    setState(() => selectedRestaurantId = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Pending orders badge
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () => Navigator.pushNamed(context, RouteNames.adminNotifications),
                              ),
                              if (pendingOrders > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    child: Text('$pendingOrders',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                            tooltip: 'Upload Pizza O Clock Menu',
                            onPressed: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                              );
                              try {
                                String? resName;
                                if (selectedRestaurantId != null) {
                                  resName = restaurantsList.firstWhere(
                                    (r) => r['id'] == selectedRestaurantId,
                                    orElse: () => {'name': 'Selected Restaurant'},
                                  )['name'];
                                }
                                
                                await _firestoreService.addPizzaOClockMenu(
                                  restaurantId: selectedRestaurantId,
                                  restaurantName: resName,
                                );
                                
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(resName != null 
                                          ? '✅ Menu uploaded to $resName!' 
                                          : '✅ Pizza O Clock menu initialized!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
                            },
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting && stats.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 1200),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide = constraints.maxWidth > 900;
                                      final isMedium = constraints.maxWidth > 600;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // ── Metric Cards ──
                                          GridView.count(
                                            crossAxisCount: isWide ? 4 : (isMedium ? 3 : 2),
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            shrinkWrap: true,
                                            childAspectRatio: 1.4,
                                            physics: const NeverScrollableScrollPhysics(),
                                            children: [
                                              _MetricCard(
                                                  label: selectedRestaurantId == null ? 'Total Orders' : 'Store Orders',
                                                  value: '$totalOrders',
                                                  icon: Icons.receipt_long,
                                                  color: AppColors.primary),
                                              _MetricCard(
                                                  label: 'Revenue',
                                                  value: 'Rs ${(totalRevenue / 1000).toStringAsFixed(1)}K',
                                                  icon: Icons.payments_outlined,
                                                  color: AppColors.green),
                                              _MetricCard(
                                                  label: 'Commission',
                                                  value: 'Rs ${(totalCommission / 1000).toStringAsFixed(1)}K',
                                                  icon: Icons.percent,
                                                  color: Colors.blue),
                                              if (selectedRestaurantId == null)
                                                _MetricCard(
                                                    label: 'Restaurants',
                                                    value: '$totalRestaurants',
                                                    icon: Icons.store,
                                                    color: AppColors.amber),
                                              _MetricCard(
                                                  label: 'Customers',
                                                  value: '$totalCustomers',
                                                  icon: Icons.people,
                                                  color: Colors.purple),
                                              _MetricCard(
                                                  label: 'Riders',
                                                  value: '$totalRiders',
                                                  icon: Icons.delivery_dining,
                                                  color: Colors.cyan),
                                            ],
                                          ),
                                          const SizedBox(height: 32),

                                          // ── Quick Actions ──
                                          const Text('Quick Actions',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                          const SizedBox(height: 16),
                                          GridView.count(
                                            crossAxisCount: isWide ? 8 : (isMedium ? 6 : 4),
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            shrinkWrap: true,
                                            childAspectRatio: 0.85,
                                            physics: const NeverScrollableScrollPhysics(),
                                            children: [
                                              _QuickAction(
                                                  label: 'Orders',
                                                  icon: Icons.receipt_long,
                                                  color: AppColors.primary,
                                                  onTap: () => _openOrders(null)),
                                              _QuickAction(
                                                  label: 'Stores',
                                                  icon: Icons.store,
                                                  color: AppColors.amber,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminStores)),
                                              _QuickAction(
                                                  label: 'Users',
                                                  icon: Icons.people,
                                                  color: Colors.blue,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminCustomers)),
                                              _QuickAction(
                                                  label: 'Riders',
                                                  icon: Icons.delivery_dining,
                                                  color: Colors.cyan,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminRiders)),
                                              _QuickAction(
                                                  label: 'Comm.',
                                                  icon: Icons.account_balance_wallet,
                                                  color: AppColors.green,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminCommissions)),
                                              _QuickAction(
                                                  label: 'Stats',
                                                  icon: Icons.bar_chart,
                                                  color: Colors.purple,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminAnalytics)),
                                              _QuickAction(
                                                  label: 'Notify',
                                                  icon: Icons.notifications_active,
                                                  color: AppColors.primary,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminNotifications)),
                                              _QuickAction(
                                                  label: 'Reports',
                                                  icon: Icons.assessment,
                                                  color: Colors.orange,
                                                  onTap: () => Navigator.pushNamed(context, RouteNames.adminPerformance)),
                                            ],
                                          ),
                                          const SizedBox(height: 32),

                                          // ── Recent Orders ──
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(selectedRestaurantId == null ? 'Recent Global Orders' : 'Recent Store Orders',
                                                  style: const TextStyle(
                                                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                              TextButton(
                                                  onPressed: () {
                                                    String? resName;
                                                    if (selectedRestaurantId != null) {
                                                      resName = restaurantsList.firstWhere(
                                                        (r) => r['id'] == selectedRestaurantId,
                                                        orElse: () => {'name': 'All Restaurants'},
                                                      )['name'];
                                                    }
                                                    _openOrders(resName);
                                                  },
                                                  child: const Text('View all',
                                                      style: TextStyle(
                                                          color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _RecentOrdersList(
                                              firestore: FirebaseFirestore.instance, restaurantId: selectedRestaurantId),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openOrders(String? restaurantName) {
    Navigator.pushNamed(
      context, 
      RouteNames.adminOrders, 
      arguments: restaurantName ?? 'All Restaurants'
    );
  }
}

// ── Recent Orders List (live from Firestore) ────────────────────────────────
class _RecentOrdersList extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String? restaurantId;

  const _RecentOrdersList({required this.firestore, this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final String? currentAdminId = FirebaseAuth.instance.currentUser?.uid;
    Query query = firestore.collection(FirestoreConstants.orders);
    
    if (currentAdminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: currentAdminId);
    }
    
    if (restaurantId != null) {
      query = query.where(FirestoreConstants.restaurantId, isEqualTo: restaurantId);
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: query
          .orderBy(FirestoreConstants.createdAt, descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AppColors.primary),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.card, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.subtle))),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data[FirestoreConstants.status] ?? FirestoreConstants.statusPending;
              final amount = (data[FirestoreConstants.totalAmount] ?? 0).toDouble();
              final orderId = doc.id.substring(0, 6).toUpperCase();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: _statusColor(status), size: 20),
                ),
                title: Text('Order #$orderId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(data[FirestoreConstants.userName] ?? 'Customer', style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rs ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    _StatusBadge(status: status),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    RouteNames.orderDetails,
                    arguments: doc.id,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    if (status == FirestoreConstants.statusDelivered) return AppColors.green;
    if (status == FirestoreConstants.statusPending) return AppColors.amber;
    if (status == FirestoreConstants.statusCancelled) return AppColors.primary;
    if (status == FirestoreConstants.statusOnTheWay) return Colors.blue;
    if (status == FirestoreConstants.statusPreparing) return Colors.orange;
    return AppColors.subtle;
  }
}

// ── Status Badge ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == FirestoreConstants.statusDelivered) {
      color = AppColors.green;
    } else if (status == FirestoreConstants.statusPending) {
      color = AppColors.amber;
    } else if (status == FirestoreConstants.statusCancelled) {
      color = AppColors.primary;
    } else if (status == FirestoreConstants.statusOnTheWay) {
      color = Colors.blue;
    } else if (status == FirestoreConstants.statusPreparing) {
      color = Colors.orange;
    } else {
      color = AppColors.subtle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Icon(Icons.more_horiz, color: AppColors.subtle, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Action ────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
