import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/pizza_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class PizzaDetailScreen extends StatefulWidget {
  const PizzaDetailScreen({super.key});

  @override
  State<PizzaDetailScreen> createState() => _PizzaDetailScreenState();
}

class _PizzaDetailScreenState extends State<PizzaDetailScreen> {
  String? selectedSize;
  int quantity = 1;
  final TextEditingController _instructionsController = TextEditingController();
  
  Map<String, bool> extraToppings = {
    "Extra Cheese": false,
    "Fresh Mushrooms": false,
    "Black Olives": false,
    "Jalapenos": false,
  };

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double _calculatePrice(double basePrice, String category) {
    double price = basePrice;
    if (selectedSize == "Small") price -= 200;
    if (selectedSize == "Large") price += 400;
    if (selectedSize == "Full") price += 250;
    
    // For deals and specific items, we don't apply size modifiers if "Standard" is selected
    // or if the category doesn't support these specific offsets.
    
    if (extraToppings["Extra Cheese"] ?? false) price += 150;
    if (extraToppings["Fresh Mushrooms"] ?? false) price += 80;
    if (extraToppings["Black Olives"] ?? false) price += 50;
    if (extraToppings["Jalapenos"] ?? false) price += 50;
    
    return price;
  }

  @override
  Widget build(BuildContext context) {
    final pizza = ModalRoute.of(context)!.settings.arguments as PizzaModel?;
    
    if (pizza == null) {
      return const Scaffold(body: Center(child: Text("No Pizza Data")));
    }

    final primary = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.text : Colors.black87;
    final subtextColor = isDark ? AppColors.subtle : Colors.grey[700];

    // Initialize selectedSize based on category if not set
    if (selectedSize == null) {
      if (pizza.category == "Pasta") {
        selectedSize = "Half";
      } else if (pizza.category == "Pizzas") {
        selectedSize = "Medium";
      } else if (pizza.name.contains("Small") || pizza.name.contains("Medium") || pizza.name.contains("Large")) {
        selectedSize = "Standard";
      } else if (["Deals", "Popular", "Deal", "P.O Clock Special", "Fun Square"].contains(pizza.category)) {
        selectedSize = "Standard";
      } else {
        selectedSize = "Medium";
      }
    }

    final currentPrice = _calculatePrice(pizza.price, pizza.category);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.background.withValues(alpha: 0.9) : surfaceColor.withValues(alpha: 0.9),
                border: Border(
                  bottom: BorderSide(color: isDark ? AppColors.border : primary.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.card : surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? null : [
                          BoxShadow(color: Colors.black12, blurRadius: 2)
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
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.subtle : Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        pizza.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.card : surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? null : [
                          BoxShadow(color: Colors.black12, blurRadius: 2)
                        ],
                        border: isDark ? Border.all(color: AppColors.border) : null,
                      ),
                      child: Icon(Icons.favorite, color: primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            pizza.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 250,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 250, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.local_pizza, size: 100),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: isDark ? AppColors.background.withValues(alpha: 0.8) : surfaceColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: primary.withValues(alpha: 0.2))),
                            child: Text(
                              "Popular Choice",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primary),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (pizza.isBestSeller)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "BEST SELLER",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Description and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pizza.name,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.star,
                                  color: primary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                pizza.rating.toString(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primary),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pizza.description,
                      style: TextStyle(fontSize: 14, color: subtextColor),
                    ),

                    const SizedBox(height: 24),

                    // Size Selection
                    if (selectedSize != "Standard") ...[
                      Text(
                        "Select Size",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: (pizza.category == "Pasta" 
                          ? ["Half", "Full"] 
                          : ["Small", "Medium", "Large"]).map((size) {
                          bool isSelected = selectedSize == size;
                          double sizePrice = pizza.price;
                          if (size == "Small") sizePrice -= 200;
                          if (size == "Large") sizePrice += 400;
                          if (size == "Full") sizePrice += 250;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSize = size;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                decoration: BoxDecoration(
                                    color:
                                        isSelected ? primary : (isDark ? AppColors.card : surfaceColor),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isSelected
                                            ? primary
                                            : (isDark ? AppColors.border : Colors.grey.shade300))),
                                child: Column(
                                  children: [
                                    Text(
                                      size,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? AppColors.text : Colors.grey[800]),
                                          letterSpacing: 1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rs. ${sizePrice.toStringAsFixed(0)}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? AppColors.subtle : Colors.grey[800])),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Ingredients
                    if (pizza.ingredients.isNotEmpty) ...[
                      Text(
                        "Ingredients",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: pizza.ingredients.map((ingredient) => _IngredientCircle(
                            icon: _getIngredientIcon(ingredient),
                            label: ingredient,
                            primary: primary,
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Extra Toppings
                    Text(
                      "Extra Toppings (Optional)",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primary),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: extraToppings.keys.map((topping) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            unselectedWidgetColor: isDark ? AppColors.subtle : Colors.grey,
                          ),
                          child: CheckboxListTile(
                            title: Text(topping, style: TextStyle(color: textColor)),
                            value: extraToppings[topping],
                            activeColor: primary,
                            checkColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                extraToppings[topping] = val!;
                              });
                            },
                            secondary: Text(
                              topping == "Extra Cheese"
                                  ? "+Rs. 150"
                                  : topping == "Fresh Mushrooms"
                                      ? "+Rs. 80"
                                      : "+Rs. 50",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: primary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Special Instructions
                    CustomTextField(
                      controller: _instructionsController,
                      label: "Special Instructions",
                      hint: "Add notes (e.g., no onions, extra spicy, etc.)",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Add to Cart Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : surfaceColor,
          border: Border(top: BorderSide(color: isDark ? AppColors.border : Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            // Quantity Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                  color: isDark ? AppColors.background : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? Border.all(color: AppColors.border) : null),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    color: isDark ? AppColors.text : Colors.black87,
                    onPressed: () {
                      setState(() {
                        if (quantity > 1) quantity--;
                      });
                    },
                  ),
                  Text(
                    "$quantity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: isDark ? AppColors.text : Colors.black87,
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart Button
            Expanded(
              child: CustomButton(
                text: "Add to Cart",
                onPressed: () {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
                  
                  // Get selected toppings
                  List<String> selectedToppings = extraToppings.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();

                  cartProvider.addToCart(
                    pizza,
                    quantity: quantity,
                    instructions: _instructionsController.text,
                    size: selectedSize ?? "Standard",
                    extraToppings: selectedToppings,
                    customPrice: currentPrice,
                    userId: authProvider.user?.uid,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${pizza.name} added to cart!"),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'VIEW CART',
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.pushNamed(context, RouteNames.cart);
                        },
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIngredientIcon(String name) {
    switch (name.toLowerCase()) {
      case 'dough': return Icons.grain;
      case 'tomato': return Icons.restaurant;
      case 'cheese': return Icons.opacity;
      case 'pepperoni': return Icons.set_meal;
      case 'onion': return Icons.eco;
      case 'mushroom': return Icons.bubble_chart;
      default: return Icons.category;
    }
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
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.text : Colors.black87),
          )
        ],
      ),
    );
  }
}


