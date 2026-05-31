import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/firestore_service.dart';
import '../../routes/route_names.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedRestaurant = 'All Restaurants';

  final List<String> _statuses = [
    'All',
    FirestoreConstants.statusPending,
    FirestoreConstants.statusPreparing,
    FirestoreConstants.statusOnTheWay,
    FirestoreConstants.statusDelivered,
    FirestoreConstants.statusCancelled,
  ];
  List<String> _restaurants = ['All Restaurants'];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args != 'All Restaurants') {
        setState(() {
          _selectedRestaurant = args;
        });
      }
    });
  }

  Future<void> _loadRestaurants() async {
    final String? currentAdminId = FirebaseAuth.instance.currentUser?.uid;
    final restaurants = await FirestoreService().getRestaurants(adminId: currentAdminId).first;
    if (mounted) {
      setState(() {
        _restaurants = ['All Restaurants', ...restaurants.map((r) => (r[FirestoreConstants.name] ?? '').toString())];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Orders')) : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Orders'),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        backgroundColor: AppColors.background,
                        elevation: 0,
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        title: const Text("Orders Management", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            children: [
                              _buildHeader(),
                              _buildFilters(),
                              Expanded(
                                child: _buildOrdersList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track and manage customer orders',
                      style: TextStyle(color: AppColors.subtle, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRestaurant,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.subtle),
                          onChanged: (value) => setState(() => _selectedRestaurant = value!),
                          items: _restaurants.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        ),
                      ),
                    ),
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: AppColors.subtle, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: AppColors.subtle, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Track and manage customer orders',
                    style: TextStyle(color: AppColors.subtle, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRestaurant,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.subtle),
                    onChanged: (value) => setState(() => _selectedRestaurant = value!),
                    items: _restaurants.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: AppColors.subtle, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.subtle, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getAllOrders(adminId: FirebaseAuth.instance.currentUser?.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var orders = snapshot.data ?? [];

        // Apply filters
        if (_selectedStatus != 'All') {
          orders = orders.where((o) => (o[FirestoreConstants.status] ?? '').toString().toLowerCase() == _selectedStatus.toLowerCase()).toList();
        }

        if (_selectedRestaurant != 'All Restaurants') {
          orders = orders.where((o) => (o[FirestoreConstants.restaurantName] ?? '').toString() == _selectedRestaurant).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          orders = orders.where((o) {
            final id = o[FirestoreConstants.id].toString().toLowerCase();
            final name = (o[FirestoreConstants.userName] ?? '').toString().toLowerCase();
            return id.contains(query) || name.contains(query);
          }).toList();
        }

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
                SizedBox(height: 16),
                Text('No orders found', style: TextStyle(color: AppColors.subtle, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String status = (order[FirestoreConstants.status] ?? FirestoreConstants.statusPending).toString();
    final DateTime createdAt = (order[FirestoreConstants.createdAt] as Timestamp?)?.toDate() ?? DateTime.now();
    final String rawId = order[FirestoreConstants.id]?.toString() ?? '';
    final String orderId = (rawId.length > 8 ? rawId.substring(0, 8) : rawId).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          RouteNames.orderDetails,
          arguments: rawId,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 500;
              
              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long, color: _getStatusColor(status)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '#$orderId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            _StatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${order[FirestoreConstants.userName] ?? 'Unknown'}',
                          style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Restaurant: ${order[FirestoreConstants.restaurantName] ?? 'Unknown'}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${(order[FirestoreConstants.totalAmount] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(createdAt),
                        style: const TextStyle(color: AppColors.subtle, fontSize: 11),
                      ),
                    ],
                  ),
                  if (!isSmall) ...[
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.subtle),
                      color: AppColors.card,
                      onSelected: (newStatus) => _updateStatus(rawId, newStatus),
                      itemBuilder: (context) => _statuses
                          .where((s) => s != 'All' && s.toLowerCase() != status.toLowerCase())
                          .map((s) => PopupMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  void _updateStatus(String orderId, String status) async {
    try {
      await FirestoreService().updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == FirestoreConstants.statusDelivered.toLowerCase()) return AppColors.green;
    if (s == FirestoreConstants.statusPending.toLowerCase()) return AppColors.amber;
    if (s == FirestoreConstants.statusCancelled.toLowerCase()) return AppColors.primary;
    if (s == FirestoreConstants.statusOnTheWay.toLowerCase() || s == 'out for delivery') return Colors.blue;
    if (s == FirestoreConstants.statusPreparing.toLowerCase()) return Colors.orange;
    return AppColors.subtle;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    final s = status.toLowerCase();
    if (s == FirestoreConstants.statusDelivered.toLowerCase()) {
      color = AppColors.green;
    } else if (s == FirestoreConstants.statusPending.toLowerCase()) {
      color = AppColors.amber;
    } else if (s == FirestoreConstants.statusCancelled.toLowerCase()) {
      color = AppColors.primary;
    } else if (s == FirestoreConstants.statusOnTheWay.toLowerCase() || s == 'out for delivery') {
      color = Colors.blue;
    } else if (s == FirestoreConstants.statusPreparing.toLowerCase()) {
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
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}


