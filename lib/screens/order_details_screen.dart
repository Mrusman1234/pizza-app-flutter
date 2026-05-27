import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_sidebar.dart';
import '../../routes/route_names.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderId;
  const OrderDetailsScreen({super.key, this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingController;
  late Animation<double> _pingAnimation;
  final FirestoreService _firestoreService = FirestoreService();
  Stream<Map<String, dynamic>?>? _orderStream;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
    _pingAnimation = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _pingController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.orderId != null && _orderStream == null) {
      _orderStream = _firestoreService.getOrderById(widget.orderId!);
    }
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  Future<void> _handleReorder(List<Map<String, dynamic>> items, Map<String, dynamic> order) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Clear existing cart first
      cartProvider.clearCart(userId: userId);

      for (var item in items) {
        final cartItem = CartItemModel.fromMap(item);
        
        // Use restaurantId from item if present, otherwise fallback to order level
        final restaurantId = item['restaurantId'] ?? order[FirestoreConstants.restaurantId];
        final restaurantName = item['restaurantName'] ?? order[FirestoreConstants.restaurantName];

        cartProvider.addToCart(
          cartItem.pizza.copyWith(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
          quantity: cartItem.quantity,
          instructions: cartItem.instructions,
          size: cartItem.size,
          extraToppings: cartItem.extraToppings,
          customPrice: cartItem.itemPrice,
          userId: userId,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items added to cart!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, RouteNames.cart);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reorder: $e')),
        );
      }
    }
  }

  Future<void> _handleCancelOrder() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.card : Colors.white,
        title: Text("Cancel Order?", style: TextStyle(color: isDark ? AppColors.text : Colors.black)),
        content: Text("Are you sure you want to cancel this order? This action cannot be undone.", style: TextStyle(color: isDark ? AppColors.subtle : Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _firestoreService.cancelOrder(widget.orderId!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to cancel order. It might already be in preparation.")),
          );
        }
      }
    }
  }

  void _showAssignRiderDialog(BuildContext context, String orderId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.card : Colors.white,
        title: Text('Assign Rider', style: TextStyle(color: isDark ? AppColors.text : Colors.black)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getAvailableRiders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              }
              final riders = snapshot.data ?? [];
              if (riders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No available riders found.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? AppColors.subtle : Colors.grey)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: riders.length,
                separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.border : Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final rider = riders[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(rider[FirestoreConstants.name] ?? 'Unknown', 
                      style: TextStyle(color: isDark ? AppColors.text : Colors.black87, fontWeight: FontWeight.bold)),
                    subtitle: Text(rider['vehicleType']?.toString().toUpperCase() ?? 'BIKE', 
                      style: TextStyle(color: isDark ? AppColors.subtle : Colors.grey)),
                    onTap: () async {
                      await _firestoreService.assignRiderToOrder(
                        orderId,
                        rider[FirestoreConstants.id],
                        rider[FirestoreConstants.name],
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rider assigned successfully')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildAssignRiderSection(BuildContext context, Map<String, dynamic> order) {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    if (authProvider.user?.role != FirestoreConstants.roleAdmin) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderId = order[FirestoreConstants.id];
    final currentRiderId = order[FirestoreConstants.riderId];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.border : AppColors.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining, color: currentRiderId != null ? AppColors.primary : Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                currentRiderId != null ? 'Assigned Rider' : 'Rider Assignment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? AppColors.text : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentRiderId != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order[FirestoreConstants.riderName] ?? 'Unknown Rider',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.text : Colors.black87)),
                      Text('Active Delivery', style: TextStyle(fontSize: 12, color: isDark ? AppColors.subtle : Colors.grey)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showAssignRiderDialog(context, orderId),
                  child: const Text('Change'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text('No rider has been assigned to this order yet.',
                      style: TextStyle(fontSize: 14, color: isDark ? AppColors.subtle : Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () => _showAssignRiderDialog(context, orderId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Assign Now'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return const Scaffold(body: Center(child: Text("Order ID is required")));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.text : Colors.black87;
    final borderColor = isDark ? AppColors.border : Colors.grey.shade100;
    final backgroundColor = isDark ? AppColors.background : const Color(0xFFf8f6f6);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _orderStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: CircularProgressIndicator())
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: Text("Order not found"))
          );
        }

        final items = List<Map<String, dynamic>>.from(order[FirestoreConstants.items] ?? []);
        final createdAt = (order[FirestoreConstants.createdAt] as Timestamp?)?.toDate() ?? DateTime.now();
        final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt);
        final status = order[FirestoreConstants.status] ?? FirestoreConstants.statusPending;
        final totalAmount = order[FirestoreConstants.totalAmount] ?? 0.0;
        final address = order[FirestoreConstants.address] ?? 'No address provided';
        final displayOrderId = order[FirestoreConstants.id].toString().length > 8 
            ? order[FirestoreConstants.id].toString().substring(0, 8).toUpperCase()
            : order[FirestoreConstants.id].toString().toUpperCase();

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            top: false,
            child: Row(
              children: [
                if (order[FirestoreConstants.userId] != Provider.of<AuthService>(context, listen: false).currentUser?.uid)
                  const AdminSidebar(activeItem: 'Orders'),
                
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Stack(
                        children: [
                          CustomScrollView(
                            slivers: [
                              SliverAppBar(
                                pinned: true,
                                floating: false,
                                backgroundColor: isDark ? AppColors.background.withValues(alpha: 0.8) : backgroundColor.withValues(alpha: 0.8),
                                surfaceTintColor: Colors.transparent,
                                flexibleSpace: FlexibleSpaceBar(
                                  background: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.arrow_back),
                                              onPressed: () => Navigator.pop(context),
                                              color: textColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Order Details',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: primary.withValues(alpha: 0.05),
                                            border: Border.all(
                                                color: primary.withValues(alpha: 0.2)),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'EN/UR',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                toolbarHeight: 70,
                                automaticallyImplyLeading: false,
                              ),

                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    _buildOrderSummaryCard(context, displayOrderId, status, formattedDate),
                                    _buildAssignRiderSection(context, order),
                                    const SizedBox(height: 16),
                                    _buildOrderItemsCard(context, items),
                                    const SizedBox(height: 16),
                                    _buildDeliveryInfoCard(context, address),
                                    const SizedBox(height: 16),
                                    _buildPriceBreakdownCard(
                                      context,
                                      totalAmount,
                                      subtotal: (order[FirestoreConstants.subtotal] ?? 0.0).toDouble(),
                                      deliveryFee: (order[FirestoreConstants.deliveryFee] ?? 0.0).toDouble(),
                                      tax: (order[FirestoreConstants.tax] ?? 0.0).toDouble(),
                                    ),
                                    const SizedBox(height: 120),
                                  ]),
                                ),
                              ),
                            ],
                          ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 800),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.card : Colors.white)
                                    .withValues(alpha: 0.95),
                                border: Border(
                                    top: BorderSide(color: borderColor, width: 1)),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              child: Row(
                                children: [
                                  if (status == FirestoreConstants.statusPending) ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _handleCancelOrder,
                                        icon: const Icon(Icons.cancel_outlined, size: 20),
                                        label: const Text('Cancel Order'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ] else ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.help_outline, size: 20),
                                        label: const Text('Need Help?'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primary,
                                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _handleReorder(items, order),
                                      icon: const Icon(Icons.replay, size: 20),
                                      label: const Text('Reorder'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, String orderId, String status, String date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isDark ? AppColors.subtle : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$orderId',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.text : Colors.black87,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.storefront, color: isDark ? AppColors.subtle : Colors.grey.shade500, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pizza Hub Vehari',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.text : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: isDark ? AppColors.border : Colors.grey.shade100),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: isDark ? AppColors.subtle : Colors.grey.shade500, size: 18),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.subtle : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    final s = status.toLowerCase();
    if (s == FirestoreConstants.statusDelivered.toLowerCase()) {
      color = AppColors.green;
    } else if (s == FirestoreConstants.statusPreparing.toLowerCase()) {
      color = AppColors.amber;
    } else if (s == FirestoreConstants.statusOnTheWay.toLowerCase() || s == 'out for delivery') {
      color = Colors.blue;
    } else if (s == FirestoreConstants.statusCancelled.toLowerCase()) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, List<Map<String, dynamic>> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.text : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.background : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length} Items',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.subtle : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? AppColors.border : Colors.grey.shade100),
          ...items.map((item) {
            List<String> modifiers = [];
            if (item['size'] != null) modifiers.add('Size: ${item['size']}');
            if (item['extraToppings'] != null && (item['extraToppings'] as List).isNotEmpty) {
              modifiers.add('Toppings: ${(item['extraToppings'] as List).join(", ")}');
            }
            if (item['instructions'] != null && item['instructions'].toString().isNotEmpty) {
              modifiers.add('Note: ${item['instructions']}');
            }
            // Fallback for old data structure
            if (modifiers.isEmpty && item['details'] != null && item['details'].toString().isNotEmpty) {
              modifiers.add(item['details'].toString());
            }

            return Column(
              children: [
                _buildOrderItem(
                  context,
                  icon: Icons.local_pizza,
                  name: item[FirestoreConstants.name] ?? 'Item',
                  price: 'Rs. ${item[FirestoreConstants.price]}',
                  quantity: item[FirestoreConstants.quantity] ?? 1,
                  modifiers: modifiers.isNotEmpty ? modifiers : null,
                ),
                if (item != items.last) Divider(height: 1, thickness: 1, color: isDark ? AppColors.border : Colors.grey.shade100),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context,
      {required IconData icon,
      required String name,
      required String price,
      required int quantity,
      List<String>? modifiers}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppColors.text : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? AppColors.text : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.subtle : Colors.grey.shade500,
                  ),
                ),
                if (modifiers != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: modifiers
                        .map((m) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.background
                                    : Colors.grey.shade50,
                                border: Border.all(
                                    color: isDark
                                        ? AppColors.border
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? AppColors.subtle
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(BuildContext context, String address) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? AppColors.text : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.subtle : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Map placeholder with ping effect
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuA_0mVON1jocpPiuebIupOOsg8d1JeX4xPbIAKvSkyNVkXGqeLv_Wq7YuazmbuIa6oxMggokuE1bzkA7jNdSNdPnr9dFEdgVrLmzgPCfb0PjbutDbM_Nfxu2b4_z3VTRBT4Fd8ydYRVfeFSxE6Jo3XWwxNlV9irvKSHer8ZaouJL3bB7qqaC-AxHQ78ogsOofZH3Tdl7oCHON1zNs2ghKVRUehUjHLhw8CiZdDrZwA3-dLOybFPU8jethr7vWh08ZZpoYx7wPkf-gPL',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: isDark ? Colors.black38 : null,
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: isDark ? AppColors.background : Colors.grey.shade300,
                  ),
                ),
              ),
              // Ping animation
              AnimatedBuilder(
                animation: _pingAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: 32 * _pingAnimation.value,
                        height: 32 * _pingAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.3 * (1 - _pingAnimation.value / 2)),
                        ),
                      ),
                      // Inner solid dot
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard(BuildContext context, double totalAmount, {required double subtotal, required double deliveryFee, required double tax}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', 'Rs. ${subtotal.toInt()}', isDark),
          const SizedBox(height: 12),
          _buildPriceRow('Delivery Fee', 'Rs. ${deliveryFee.toInt()}', isDark),
          const SizedBox(height: 12),
          _buildPriceRow('Tax (GST)', 'Rs. ${tax.toInt()}', isDark),
          const SizedBox(height: 16),
          Divider(height: 2, thickness: 1, color: isDark ? AppColors.border : Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? AppColors.text : Colors.black87,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FINAL TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primary.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Rs. ${totalAmount.toInt()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.subtle : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.text : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}


