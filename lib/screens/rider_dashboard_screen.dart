import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/firestore_constants.dart';
import '../routes/route_names.dart';
import '../providers/auth_provider.dart';
import '../providers/rider_provider.dart';
import '../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../providers/notification_provider.dart';
import '../services/firestore_service.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(userId);
      }
    });
  }

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates not available')),
      );
      return;
    }

    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
    final fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open maps: $e');
    }
  }

  Future<void> _showPinDialog(String orderId, String? correctPin) async {
    final authProvider = context.read<AppAuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (correctPin == null) {
      // Fallback for older orders without a PIN
      await _firestoreService.completeOrder(orderId, authProvider.user!.uid);
      messenger.showSnackBar(const SnackBar(content: Text('✅ Delivery Completed!'), backgroundColor: Colors.green));
      return;
    }

    final pinController = TextEditingController();
    final bool? verified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Verify Delivery', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ask the customer for their 4-digit Delivery PIN.', style: TextStyle(color: AppColors.subtle, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: TextStyle(color: AppColors.muted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == correctPin) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Incorrect PIN'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Verify & Complete'),
          ),
        ],
      ),
    );

    if (verified == true) {
      final uid = authProvider.user!.uid;
      await _firestoreService.completeOrder(orderId, uid);
      messenger.showSnackBar(const SnackBar(content: Text('✅ Delivery Completed!'), backgroundColor: Colors.green));
    }
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rider Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              Text(currentRider?.status.toUpperCase() ?? 'OFFLINE', 
                  style: TextStyle(color: _getStatusColor(currentRider?.status ?? 'offline'), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          actions: [
             IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: () => setState(() {}),
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'My Orders', icon: Icon(Icons.delivery_dining)),
              Tab(text: 'Marketplace', icon: Icon(Icons.explore_outlined)),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        drawer: _buildDrawer(authProvider, currentRider, user),
        body: user == null
            ? const Center(child: Text("Please login to see deliveries", style: TextStyle(color: Colors.white)))
            : TabBarView(
                children: [
                  _buildMyTasksTab(user.uid),
                  _buildMarketplaceTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer(AppAuthProvider auth, dynamic rider, dynamic user) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.card),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(user?.name?.substring(0, 1).toUpperCase() ?? 'R',
                  style: const TextStyle(fontSize: 24, color: Colors.white)),
            ),
            accountName: Text(user?.name ?? 'Rider', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? '', style: const TextStyle(color: AppColors.subtle)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text('My Profile', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushNamed(context, RouteNames.profile),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            title: const Text('My Earnings', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushNamed(context, RouteNames.wallet),
          ),
          const Divider(color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Go Online', style: TextStyle(color: Colors.white, fontSize: 16)),
                Switch(
                  value: rider?.status != FirestoreConstants.riderStatusOffline,
                  onChanged: (value) async {
                    final newStatus = value ? FirestoreConstants.riderStatusAvailable : FirestoreConstants.riderStatusOffline;
                    if (user?.uid != null) await _firestoreService.updateRiderStatus(user!.uid, newStatus);
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
              await auth.logout(context);
              if (mounted) Navigator.of(context).pushReplacementNamed(RouteNames.login);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMyTasksTab(String riderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseSnapshotHelper.getMyOrders(riderId),
      builder: (context, snapshot) {
        return _buildOrderList(snapshot, "No active tasks.\nGo to Marketplace to find orders.", isMyTasks: true);
      },
    );
  }

  Widget _buildMarketplaceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseSnapshotHelper.getMarketplaceOrders(),
      builder: (context, snapshot) {
        return _buildOrderList(snapshot, "Marketplace is empty.\nCheck back later!");
      },
    );
  }

  Widget _buildOrderList(AsyncSnapshot<QuerySnapshot> snapshot, String emptyMessage, {bool isMyTasks = false}) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    
    final orders = snapshot.data?.docs ?? [];
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.subtle, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final orderDoc = orders[index];
        final data = orderDoc.data() as Map<String, dynamic>;
        return _buildOrderCard(orderDoc.id, data, isMyTasks);
      },
    );
  }

  Widget _buildOrderCard(String id, Map<String, dynamic> data, bool isMyTasks) {
    final status = data[FirestoreConstants.status] ?? 'pending';
    final restaurant = data[FirestoreConstants.restaurantName] ?? 'Restaurant';
    final address = data[FirestoreConstants.address] ?? 'No Address';
    final total = data[FirestoreConstants.totalAmount] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.pushNamed(context, RouteNames.orderDetails, arguments: id),
            title: Row(
              children: [
                Text('#${id.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildStatusChip(status),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.store, size: 14, color: AppColors.primary), const SizedBox(width: 6), Text(restaurant, style: const TextStyle(color: Colors.white70))]),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.redAccent), const SizedBox(width: 6), Expanded(child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.subtle)))]),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rs. $total', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                _buildActionButton(id, status, isMyTasks, data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String orderId, String status, bool isMyTasks, Map<String, dynamic> data) {
    if (!isMyTasks) {
      return CustomButton(
        text: 'Accept Order',
        isSmall: true,
        width: 130,
        onPressed: () async {
          final auth = context.read<AppAuthProvider>();
          await _firestoreService.acceptOrder(orderId, auth.user!.uid, auth.user!.name);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Accepted! Check "My Orders"')));
        },
      );
    }

    // Workflow: Preparing (at store) -> Start Delivery (On the Way) -> Complete (Delivered)
    if (status == FirestoreConstants.statusPreparing || status == 'Confirmed') {
      return CustomButton(
        text: 'Picked Up',
        isSmall: true,
        width: 120,
        color: Colors.orange,
        onPressed: () => _firestoreService.updateOrderStatus(orderId, FirestoreConstants.statusOnTheWay),
      );
    }

    if (status == FirestoreConstants.statusOnTheWay) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.blue),
            onPressed: () => _openMaps(data['deliveryLat'], data['deliveryLng']),
          ),
          const SizedBox(width: 8),
          CustomButton(
            text: 'Set Delivered',
            isSmall: true,
            width: 130,
            color: Colors.green,
            onPressed: () => _showPinDialog(orderId, data['deliveryPin']),
          ),
        ],
      );
    }

    return const Icon(Icons.check_circle, color: Colors.green);
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status.toLowerCase().contains('way')) color = Colors.blue;
    if (status.toLowerCase().contains('prepare')) color = Colors.orange;
    if (status.toLowerCase().contains('deliver')) color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    if (status == FirestoreConstants.riderStatusAvailable) return Colors.green;
    if (status == FirestoreConstants.riderStatusBusy) return Colors.orange;
    return Colors.redAccent;
  }
}

class FirebaseSnapshotHelper {
  static Stream<QuerySnapshot> getMyOrders(String riderId) {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.riderId, isEqualTo: riderId)
        .where(FirestoreConstants.status, whereIn: [
          FirestoreConstants.statusPreparing,
          FirestoreConstants.statusOnTheWay,
          'Confirmed', // Include confirmed but not yet picked up
        ])
        .snapshots();
  }

  static Stream<QuerySnapshot> getMarketplaceOrders() {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.status, isEqualTo: FirestoreConstants.statusPending)
        .orderBy(FirestoreConstants.createdAt, descending: true)
        .snapshots();
  }
}
