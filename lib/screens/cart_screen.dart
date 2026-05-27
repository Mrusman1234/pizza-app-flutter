import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedAddress = "Vehari City Center, Punjab";
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final cartItems = cartProvider.items;
    final double subtotal = cartProvider.subtotal;
    final double discount = cartProvider.discountAmount;
    const double deliveryFee = 50.0;
    const double tax = 100.0;
    final double totalAmount = cartItems.isEmpty ? 0 : (subtotal - discount) + deliveryFee + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            /// APP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.text),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text("Your Cart",
                      style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
                    Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.primary),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("Clear Cart?", style: TextStyle(color: AppColors.text)),
                            content: const Text("Are you sure you want to remove all items from your cart?", style: TextStyle(color: AppColors.subtle)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel", style: TextStyle(color: AppColors.subtle)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                onPressed: () {
                                  cartProvider.clearCart(userId: userId);
                                  Navigator.pop(context);
                                },
                                child: const Text("Clear All"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (cartItems.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140, height: 140,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: const Icon(Icons.shopping_basket_outlined, size: 54, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text("Your cart is empty", 
                          style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text("Hungry? Add some delicious pizzas to your cart and satisfy your cravings!", 
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.subtle, fontSize: 14, height: 1.5)),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 220,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Start Ordering", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// DELIVERY ADDRESS
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("DELIVERY ADDRESS", style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  const SizedBox(height: 4),
                                  Text(_selectedAddress, 
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {}, // TODO: Address selection
                              child: const Text("Change", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 16, 12),
                        child: Text("ORDER ITEMS", style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),

                      /// CART ITEMS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: cartItems.map((item) => _buildCartItem(item, cartProvider, userId)).toList(),
                        ),
                      ),

                      /// PROMO
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _promoController,
                                    enabled: cartProvider.appliedPromo == null,
                                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: "Enter promo code",
                                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (cartProvider.appliedPromo != null)
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: AppColors.muted, size: 20),
                                    onPressed: () {
                                      cartProvider.removePromoCode();
                                      _promoController.clear();
                                    },
                                  )
                                else
                                  _isApplyingPromo 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                    : TextButton(
                                        onPressed: () async {
                                          if (_promoController.text.isEmpty) return;
                                          setState(() => _isApplyingPromo = true);
                                          final error = await cartProvider.applyPromoCode(_promoController.text);
                                          setState(() => _isApplyingPromo = false);
                                          
                                          if (mounted) {
                                            if (error != null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(error), backgroundColor: Colors.red),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Promo code applied successfully!"), backgroundColor: AppColors.green),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text("Apply", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      ),
                              ],
                            ),
                            if (cartProvider.appliedPromo != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: AppColors.green, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Code "${cartProvider.appliedPromo!['code']}" applied! -Rs ${discount.toInt()}',
                                      style: const TextStyle(color: AppColors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      /// SUMMARY
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _summaryRow("Subtotal", "Rs. ${subtotal.toInt()}"),
                            if (discount > 0) ...[
                              const SizedBox(height: 12),
                              _summaryRow(
                                "Discount ${cartProvider.appliedPromo != null ? '(${cartProvider.appliedPromo!['discountType'] == 'percentage' ? '${cartProvider.appliedPromo!['discountValue'] ?? cartProvider.appliedPromo!['discountPercent']}%' : 'Flat Rs. ${cartProvider.appliedPromo!['discountValue']}'})' : ''}", 
                                "- Rs. ${discount.toInt()}", 
                                valueColor: AppColors.green
                              ),
                            ],
                            const SizedBox(height: 12),
                            _summaryRow("Delivery Fee", "Rs. ${deliveryFee.toInt()}", valueColor: AppColors.green),
                            const SizedBox(height: 12),
                            _summaryRow("Tax (GST)", "Rs. ${tax.toInt()}"),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppColors.border, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total", style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("Rs. ${totalAmount.toInt()}", style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: cartItems.isEmpty ? null : Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                RouteNames.checkout,
                arguments: {
                  'items': cartItems,
                  'subtotal': subtotal,
                  'deliveryFee': deliveryFee,
                  'tax': tax,
                  'totalAmount': totalAmount,
                  'promoDiscount': discount,
                  'promoCode': cartProvider.appliedPromo?['code'],
                },
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Checkout Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text("Rs. ${totalAmount.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item, CartProvider provider, String? userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.pizza.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.pizza.name, 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => provider.removeItem(item.pizza.id, size: item.size, extraToppings: item.extraToppings, userId: userId),
                      child: const Icon(Icons.close, color: AppColors.muted, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(item.size ?? "Standard", style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    if (item.pizza.restaurantName != null) ...[
                      const Text("  •  ", style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      Expanded(
                        child: Text(item.pizza.restaurantName!, 
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rs. ${item.itemPrice.toInt()}", style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _quantityButton(
                            icon: Icons.remove, 
                            onPressed: () {
                              if (item.quantity == 1) {
                                _showRemoveItemDialog(context, item, provider, userId);
                              } else {
                                provider.updateQuantity(item.pizza.id, item.quantity - 1, size: item.size, extraToppings: item.extraToppings, userId: userId);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("${item.quantity}", style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          _quantityButton(
                            icon: Icons.add, 
                            onPressed: () => provider.updateQuantity(item.pizza.id, item.quantity + 1, size: item.size, extraToppings: item.extraToppings, userId: userId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.subtle, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.text, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: AppColors.text),
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, dynamic item, CartProvider provider, String? userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Item?", style: TextStyle(color: AppColors.text)),
        content: Text("Do you want to remove ${item.pizza.name} from your cart?", style: const TextStyle(color: AppColors.subtle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, Keep it", style: TextStyle(color: AppColors.subtle)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              provider.removeItem(item.pizza.id, size: item.size, extraToppings: item.extraToppings, userId: userId);
              Navigator.pop(context);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}


