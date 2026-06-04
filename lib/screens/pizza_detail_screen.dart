import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/pizza_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PizzaDetailScreen extends StatefulWidget {
  const PizzaDetailScreen({super.key});

  @override
  State<PizzaDetailScreen> createState() => _PizzaDetailScreenState();
}

class _PizzaDetailScreenState extends State<PizzaDetailScreen> {
  String? selectedSize;
  int quantity = 1;
  final TextEditingController _instructionsController = TextEditingController();

  final Map<String, bool> extraToppings = {
    'Extra Cheese': false,
    'Mushrooms': false,
    'Olives': false,
    'Onions': false,
  };

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double _calculatePrice(double basePrice, String category) {
    double price = basePrice;
    if (selectedSize == 'Medium') price += 200;
    if (selectedSize == 'Large') price += 400;
    
    extraToppings.forEach((key, value) {
      if (value) price += 50;
    });
    
    return price * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final pizza = ModalRoute.of(context)!.settings.arguments as PizzaModel?;
    
    if (pizza == null) {
      return const Scaffold(body: Center(child: Text("No Pizza Data")));
    }

    // DEBUG LOGS
    debugPrint('🔍 Opening PizzaDetailScreen for: ${pizza.name}');
    debugPrint('🆔 Pizza ID: "${pizza.id}"');
    debugPrint('🏪 Restaurant ID: "${pizza.restaurantId}"');

    if (pizza.id.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Error: Missing Product ID", style: TextStyle(color: Colors.red)),
        ),
      );
    }

    final authProvider = context.watch<AppAuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: pizza.restaurantId.isNotEmpty 
          ? FirestoreService().getRestaurantByIdStream(pizza.restaurantId)
          : Stream.value(null),
      builder: (context, resSnapshot) {
        if (pizza.restaurantId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("Error: Missing Restaurant Reference", style: TextStyle(color: Colors.red)),
            ),
          );
        }

        final restaurantData = resSnapshot.data;
        final bool isRestaurantEnabled = restaurantData?['isEnabled'] ?? true;

        return Scaffold(
          backgroundColor: surfaceColor,
          body: SafeArea(
            child: Column(
              children: [
                if (!isRestaurantEnabled)
                  Container(
                    width: double.infinity,
                    color: Colors.red.withAlpha(50),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Restaurant is currently closed or ordering is disabled.',
                            style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.card : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? null : [
                              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4)
                            ],
                            border: isDark ? Border.all(color: AppColors.border) : null,
                          ),
                          child: Icon(Icons.arrow_back, color: isDark ? AppColors.text : Colors.grey[700]),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "Menu Detail",
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600]),
                          ),
                          Text(
                            pizza.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      StreamBuilder<bool>(
                        stream: (authProvider.user != null && pizza.id.isNotEmpty)
                          ? FirestoreService().isFavorite(authProvider.user!.uid, pizza.id)
                          : Stream.value(false),
                        builder: (context, snapshot) {
                          final isFav = snapshot.data ?? false;
                          return InkWell(
                            onTap: () async {
                              if (authProvider.user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please login to favorite items")),
                                );
                                return;
                              }
                              await FirestoreService().toggleFavorite(authProvider.user!.uid, pizza.id);
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.card : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: isDark ? null : [
                                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4)
                                ],
                                border: isDark ? Border.all(color: AppColors.border) : null,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : (isDark ? AppColors.text : Colors.grey[700]),
                                size: 22,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pizza Image Stack
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: Image.network(
                                  pizza.imageUrl,
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: double.infinity,
                                    height: 300,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.local_pizza, size: 100, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Popular Choice",
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "BEST SELLER",
                                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      pizza.name,
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          pizza.rating.toString(),
                                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.amber : Colors.amber[900]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                pizza.description,
                                style: TextStyle(fontSize: 15, color: isDark ? Colors.grey : Colors.grey[600], height: 1.5),
                              ),
                              
                              const SizedBox(height: 24),
                              Text("Select Size", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 16),
                              Row(
                                children: ['Small', 'Medium', 'Large'].map((size) {
                                  bool isSelected = selectedSize == size;
                                  double sizePrice = pizza.price;
                                  if (size == 'Medium') sizePrice += 200;
                                  if (size == 'Large') sizePrice += 400;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => selectedSize = size),
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          right: size == 'Large' ? 0 : 12,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : (isDark ? AppColors.card : Colors.white),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : (isDark ? AppColors.border : Colors.grey[300]!),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              size,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Rs. ${sizePrice.toStringAsFixed(0)}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected ? Colors.white70 : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 30),
                              Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _IngredientCircle(icon: Icons.local_pizza, label: "Cheese", primary: Colors.orange),
                                    _IngredientCircle(icon: Icons.eco, label: "Veggie", primary: Colors.green),
                                    _IngredientCircle(icon: Icons.set_meal, label: "Protein", primary: Colors.red),
                                    _IngredientCircle(icon: Icons.grain, label: "Spice", primary: Colors.deepOrange),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),
                              Text("Extra Toppings (Optional)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 8),
                              Column(
                                children: extraToppings.keys.map((topping) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(unselectedWidgetColor: isDark ? Colors.white54 : Colors.grey),
                                    child: CheckboxListTile(
                                      title: Text(topping, style: TextStyle(color: textColor, fontSize: 15)),
                                      subtitle: Text(topping == 'Extra Cheese' ? '+Rs. 100' : '+Rs. 50', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                      value: extraToppings[topping],
                                      activeColor: AppColors.primary,
                                      checkColor: Colors.white,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (val) => setState(() => extraToppings[topping] = val!),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _instructionsController,
                                label: "Special Instructions",
                                hint: "e.g. No onions, extra spicy",
                                maxLines: 3,
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.card : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF121212) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => quantity > 1 ? quantity-- : null),
                              icon: const Icon(Icons.remove, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => quantity++),
                              icon: const Icon(Icons.add, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: isRestaurantEnabled ? "Add to Cart • Rs. ${_calculatePrice(pizza.price, pizza.category).toStringAsFixed(0)}" : "Currently Unavailable",
                          onPressed: isRestaurantEnabled ? () {
                            if (selectedSize == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please select a size")),
                              );
                              return;
                            }
                            context.read<CartProvider>().addToCart(
                                  pizza,
                                  quantity: quantity,
                                  size: selectedSize,
                                  instructions: _instructionsController.text,
                                  userId: authProvider.user?.uid,
                                );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${pizza.name} added to cart!"),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _IngredientCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;

  const _IngredientCircle({
    required this.icon,
    required this.label,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? AppColors.card : Colors.grey[200],
            child: Icon(icon, color: primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
