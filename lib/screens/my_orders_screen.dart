import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../routes/route_names.dart';
import '../providers/cart_provider.dart';
import '../models/cart_model.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Stream<List<Map<String, dynamic>>>? _ordersStream;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context);
    final newUserId = authService.currentUser?.uid;
    if (newUserId != _userId) {
      _userId = newUserId;
      if (_userId != null) {
        _ordersStream = _firestoreService.getOrders(_userId!);
      } else {
        _ordersStream = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_userId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text("My Orders"),
          backgroundColor: isDark ? AppColors.background : Colors.white,
          foregroundColor: isDark ? AppColors.text : Colors.black,
        ),
        body: Center(
          child: Text(
            "Please login to see your orders",
            style: TextStyle(color: isDark ? AppColors.subtle : Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFf8f6f6),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.background : Colors.white,
        foregroundColor: isDark ? AppColors.text : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading orders",
                style: TextStyle(color: isDark ? AppColors.text : Colors.black),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: isDark ? AppColors.card2 : Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No orders found", 
                    style: TextStyle(fontSize: 18, color: isDark ? AppColors.subtle : Colors.grey)
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final date = (order[FirestoreConstants.createdAt] as Timestamp?)?.toDate() ?? DateTime.now();
              final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
              final status = (order[FirestoreConstants.status] ?? 'Pending').toString();
              final total = order[FirestoreConstants.totalAmount] ?? 0.0;
              final String rawId = order[FirestoreConstants.id]?.toString() ?? '';
              final orderId = rawId.length > 8 
                  ? rawId.substring(0, 8).toUpperCase()
                  : rawId.toUpperCase();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.card : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: AppColors.border) : null,
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.orderDetails,
                      arguments: rawId,
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
                              'Order #$orderId',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                color: isDark ? AppColors.text : Colors.black,
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate, 
                          style: TextStyle(
                            color: isDark ? AppColors.subtle : Colors.grey.shade600, 
                            fontSize: 13
                          )
                        ),
                        Divider(
                          height: 32, 
                          color: isDark ? AppColors.border : Colors.grey.shade200
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(order[FirestoreConstants.items] as List?)?.length ?? 0} Items',
                              style: TextStyle(
                                color: isDark ? AppColors.subtle : Colors.grey.shade700, 
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            Text(
                              'Rs. $total',
                              style: TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: 18, 
                                color: primary
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.orderDetails,
                                    arguments: rawId,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: isDark ? AppColors.border : const Color(0x33EC5B13)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'View Details', 
                                  style: TextStyle(color: isDark ? AppColors.text : primary)
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (status.toLowerCase() == FirestoreConstants.statusDelivered.toLowerCase())
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                    final items = order[FirestoreConstants.items] as List?;
                                    if (items != null) {
                                      for (var item in items) {
                                        final cartItem = CartItemModel.fromMap(item as Map<String, dynamic>);
                                        cartProvider.addToCart(
                                          cartItem.pizza,
                                          quantity: cartItem.quantity,
                                          instructions: cartItem.instructions,
                                          size: cartItem.size,
                                          extraToppings: cartItem.extraToppings,
                                          customPrice: cartItem.itemPrice,
                                          userId: _userId,
                                        );
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Items added to cart')),
                                      );
                                      Navigator.pushNamed(context, RouteNames.cart);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Reorder', 
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
