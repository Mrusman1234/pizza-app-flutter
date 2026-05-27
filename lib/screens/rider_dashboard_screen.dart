import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../routes/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../providers/notification_provider.dart';
import '../../services/firestore_service.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      if (authProvider.user?.uid != null) {
        final userId = authProvider.user!.uid;
        final riderProvider = Provider.of<RiderProvider>(context, listen: false);
        riderProvider.startLocationUpdates(userId);
        riderProvider.listenToCurrentRider(userId);
        
        // Listen to notifications to potentially refresh data or show alerts
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final riderProvider = Provider.of<RiderProvider>(context);
    final user = authProvider.user;
    final currentRider = riderProvider.currentRider;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Rider Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await authProvider.logout(context);
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'My Tasks', icon: Icon(Icons.task_alt)),
              Tab(text: 'Marketplace', icon: Icon(Icons.storefront)),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppColors.background,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppColors.card),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.email.substring(0, 1).toUpperCase() ?? 'R',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                accountName: Text(currentRider?.name ?? user?.name ?? 'Rider',
                    style: const TextStyle(color: Colors.white)),
                accountEmail: Text(user?.email ?? '',
                    style: const TextStyle(color: AppColors.subtle)),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Navigate to profile
                },
              ),
              const Divider(color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Availability',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    Switch(
                      value: currentRider?.status != FirestoreConstants.riderStatusOffline,
                      onChanged: (value) async {
                        final newStatus = value
                            ? FirestoreConstants.riderStatusAvailable
                            : FirestoreConstants.riderStatusOffline;
                        if (user?.uid != null) {
                          await FirestoreService().updateRiderStatus(user!.uid, newStatus);
                        }
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  await authProvider.logout(context);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        body: user == null
            ? const Center(
                child: Text("Please login to see deliveries",
                    style: TextStyle(color: Colors.white)))
            : TabBarView(
                children: [
                  _buildMyTasksTab(user.uid),
                  _buildMarketplaceTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildMyTasksTab(String riderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.riderId, isEqualTo: riderId)
          .where(FirestoreConstants.status, whereIn: [
            FirestoreConstants.statusPreparing,
            FirestoreConstants.statusOnTheWay,
          ])
          .snapshots(),
      builder: (context, snapshot) {
        return _buildOrderList(snapshot, "No active tasks assigned to you.", isMyTasks: true);
      },
    );
  }

  Widget _buildMarketplaceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.status, isEqualTo: FirestoreConstants.statusPending)
          .snapshots(),
      builder: (context, snapshot) {
        return _buildOrderList(snapshot, "No orders available in the marketplace.");
      },
    );
  }

  Widget _buildOrderList(AsyncSnapshot<QuerySnapshot> snapshot, String emptyMessage, {bool isMyTasks = false}) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delivery_dining, size: 64, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Text(emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      );
    }

    final orders = snapshot.data!.docs;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final orderDoc = orders[index];
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final orderId = orderDoc.id;
        final status = orderData[FirestoreConstants.status] ?? FirestoreConstants.statusPending;
        final address = orderData[FirestoreConstants.address] ?? 'No address';
        final total = orderData[FirestoreConstants.totalAmount] ?? 0;
        final restaurantName = orderData[FirestoreConstants.restaurantName] ?? 'Unknown Restaurant';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                RouteNames.orderDetails,
                arguments: orderId,
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(restaurantName,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(address,
                            style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PKR $total',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 18)),
                      if (isMyTasks)
                        Row(
                          children: [
                            if (status == FirestoreConstants.statusPreparing)
                              CustomButton(
                                text: 'Start Delivery',
                                onPressed: () async {
                                  final firestoreService = FirestoreService();
                                  await firestoreService.updateOrderStatus(
                                      orderId, FirestoreConstants.statusOnTheWay);
                                },
                                isSmall: true,
                                width: 120,
                              ),
                            if (status == FirestoreConstants.statusOnTheWay)
                              CustomButton(
                                text: 'Complete',
                                onPressed: () async {
                                  final firestoreService = FirestoreService();
                                  final riderId =
                                      Provider.of<AppAuthProvider>(context, listen: false)
                                          .user!
                                          .uid;
                                  await firestoreService.completeOrder(orderId, riderId);
                                },
                                isSmall: true,
                                width: 100,
                                color: Colors.green,
                              ),
                          ],
                        )
                      else if (status == FirestoreConstants.statusPending)
                        CustomButton(
                          text: 'Accept',
                          onPressed: () async {
                            final firestoreService = FirestoreService();
                            final auth = Provider.of<AppAuthProvider>(context, listen: false);
                            final riderId = auth.user?.uid;
                            if (riderId == null) return;
                            final riderName = auth.user?.name ?? 'Rider';
                            await firestoreService.acceptOrder(orderId, riderId, riderName);
                          },
                          isSmall: true,
                          width: 80,
                        )
                      else
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    final s = status.toLowerCase();
    if (s == FirestoreConstants.statusPreparing.toLowerCase()) color = Colors.orange;
    if (s == FirestoreConstants.statusOnTheWay.toLowerCase() || s == 'out for delivery') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
