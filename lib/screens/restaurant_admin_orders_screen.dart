import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/firestore_constants.dart';
import '../providers/restaurant_admin_provider.dart';
import '../services/firestore_service.dart';
import '../routes/route_names.dart';

class RestaurantAdminOrdersScreen extends StatefulWidget {
  const RestaurantAdminOrdersScreen({super.key});

  @override
  State<RestaurantAdminOrdersScreen> createState() => _RestaurantAdminOrdersScreenState();
}

class _RestaurantAdminOrdersScreenState extends State<RestaurantAdminOrdersScreen> {
  String _selectedStatus = 'All';
  final List<String> _statuses = [
    'All',
    FirestoreConstants.statusPending,
    FirestoreConstants.statusPreparing,
    FirestoreConstants.statusOnTheWay,
    FirestoreConstants.statusDelivered,
    FirestoreConstants.statusCancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantAdminProvider>();
    final admin = provider.adminModel;

    if (admin == null) {
      return const Scaffold(body: Center(child: Text('Admin data not loaded')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Orders', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(admin.assignedRestaurantName, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _buildOrdersList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedStatus = status);
              },
              backgroundColor: AppColors.card,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.subtle,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(RestaurantAdminProvider provider) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: provider.ordersStream(statusFilter: _selectedStatus),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
                const SizedBox(height: 16),
                Text('No $_selectedStatus orders found', style: const TextStyle(color: AppColors.subtle)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final order = docs[index].data();
            final orderId = docs[index].id;
            return _buildOrderCard(order, orderId);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String orderId) {
    final status = order[FirestoreConstants.status] as String? ?? 'Pending';
    final total = (order[FirestoreConstants.totalAmount] as num?)?.toDouble() ?? 0;
    final customer = order[FirestoreConstants.userName] as String? ?? 'Customer';
    final createdAt = order[FirestoreConstants.createdAt] as Timestamp?;
    final dateStr = createdAt != null ? DateFormat('MMM dd, hh:mm a').format(createdAt.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.pushNamed(context, RouteNames.orderDetails, arguments: orderId),
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text('#${orderId.substring(0, 8).toUpperCase()}', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('Rs ${total.toStringAsFixed(0)}', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.subtle),
                    const SizedBox(width: 4),
                    Text(customer, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.subtle),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: _buildStatusBadge(status),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (status == FirestoreConstants.statusPending)
                  _buildActionButton('Prepare', Icons.restaurant, Colors.blue, () => _updateStatus(orderId, FirestoreConstants.statusPreparing)),
                if (status == FirestoreConstants.statusPreparing)
                  _buildActionButton('Hand Over', Icons.delivery_dining, Colors.purple, () => _updateStatus(orderId, FirestoreConstants.statusOnTheWay)),
                if (status == FirestoreConstants.statusOnTheWay)
                  _buildActionButton('Delivered', Icons.check_circle, AppColors.green, () => _updateStatus(orderId, FirestoreConstants.statusDelivered)),
                _buildActionButton('Cancel', Icons.cancel, Colors.redAccent, () => _updateStatus(orderId, FirestoreConstants.statusCancelled)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':    return AppColors.amber;
      case 'Preparing':  return Colors.blueAccent;
      case 'On the way': return Colors.purpleAccent;
      case 'Delivered':  return AppColors.green;
      case 'Cancelled':  return Colors.redAccent;
      default:           return AppColors.subtle;
    }
  }

  void _updateStatus(String orderId, String status) async {
    try {
      await FirestoreService().updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as $status'),
            backgroundColor: _getStatusColor(status),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
