import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/pizza_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../routes/route_names.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;
  const RestaurantMenuScreen({super.key, this.restaurantId, this.restaurantName});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String _activeCategory = 'Appetizer';

  static const Map<String, List<Map<String, dynamic>>> _poClockMenu = {
    'Appetizer': [
      {'name': 'Cheesey Sticks', 'price': 480, 'description': '4 pieces of cheese & white sauce stuffed bread sticks served with dip sauce'},
      {'name': 'Oven Baked Wings - Honey (12 pcs)', 'price': 760, 'description': 'Honey wings (12 pcs)'},
      {'name': 'Oven Baked Wings - Spicy (12 pcs)', 'price': 740, 'description': 'Spicy & juicy wings (12 pcs)'},
      {'name': 'Oven Baked Wings - Honey (6 pcs)', 'price': 380, 'description': 'Honey wings (6 pcs)'},
      {'name': 'Oven Baked Wings - Spicy (6 pcs)', 'price': 410, 'description': 'Spicy & juicy wings (6 pcs)'},
      {'name': 'Kabab Sticks', 'price': 500, 'description': '4 pieces of white sauce loaded kebab stuffed bread sticks served with dip sauce'},
      {'name': 'Mexican Sandwich', 'price': 670, 'description': 'A bun baked with chicken, veggies & cheese with the twist of mayo mustard sauce'},
      {'name': 'Oven Baked Rolls', 'price': 610, 'description': 'Four types of delicious fresh & juicy rolls served with mayo dip sauce'},
      {'name': 'Platter', 'price': 910, 'description': '4 pieces of spring rolls served with juicy 6 oven baked wings & mayo dip sauce'},
    ],
    'P.O Clock Special': [
      {'name': 'Zinger Burger', 'price': 390, 'description': 'Crispy chicken zinger with specialized mayo sauce'},
      {'name': 'Patty Burger', 'price': 350, 'description': 'Classic chicken patty burger'},
      {'name': 'Cheese Patty Burger', 'price': 400, 'description': 'Chicken patty burger with cheese slice'},
      {'name': 'Cheese Zinger Burger', 'price': 440, 'description': 'Crispy zinger burger with cheese slice'},
      {'name': 'Nuggets (12 pcs)', 'price': 490, 'description': '12 pieces of crispy nuggets'},
      {'name': 'Nuggets (6 pcs)', 'price': 330, 'description': '6 pieces of crispy nuggets'},
      {'name': 'French Fries - Family', 'price': 550, 'description': 'Family size crispy french fries'},
      {'name': 'French Fries - Single', 'price': 350, 'description': 'Single serving crispy french fries'},
      {'name': 'Loaded Fries', 'price': 650, 'description': 'Crispy fries loaded with cheese and chicken toppings'},
    ],
    'Deals': [
      {'name': 'Deal 1', 'price': 600, 'description': '1 Small Pizza, 1 Drink 500ml'},
      {'name': 'Deal 2', 'price': 1240, 'description': '1 Medium Special Pizza, 1 Drink 500ml'},
      {'name': 'Deal 3', 'price': 1510, 'description': '2 Small Pizza, 1 F1 Pasta, 1 Drink 500ml'},
      {'name': 'Deal 4', 'price': 1690, 'description': '1 Large Special Pizza, 1 Drink 1.5 Ltr'},
      {'name': 'Deal 5', 'price': 2390, 'description': '1 Large Pizza, 1 Pasta, 1 Drink 1.5 Ltr'},
      {'name': 'Deal 6', 'price': 3300, 'description': '2 Large Special Pizza, 1 Drink 1.5 Ltr'},
      {'name': 'Mega Deal', 'price': 4999, 'description': 'Only Tuesday Night: 3 Large Special Pizzas, 2 Drinks 1.5 Ltr'},
      {'name': 'Royal Deal', 'price': 3900, 'description': '2 Large Special Pizzas, 12 Pcs Wings, 1.5 Ltr Drink'},
      {'name': 'Family Ties', 'price': 4900, 'description': '1 Large Square Pizza, 1 Medium Square Pizza, 12 Pcs Wings, 1 Small Pasta, 2 Drinks 1.5 Ltr'},
      {'name': 'Birthday Bash', 'price': 7270, 'description': '3 Square Pizzas, 2 Drinks 1.5 Ltr, 12 Pcs Wings'},
      {'name': 'Square Deal', 'price': 2310, 'description': '1 Square Pizza, 1 Drink 1.5 Ltr'},
      {'name': 'Chaska Deal', 'price': 1060, 'description': '1 Pasta, 6 Pcs Wings, 1 Drink 500ml'},
      {'name': 'Zinger Deal 1', 'price': 850, 'description': '1 Zinger Burger, 1 Fries, 1 Drink 500ml'},
      {'name': 'Zinger Deal 2', 'price': 1700, 'description': '3 Zinger Burger, 1 Fries, 1 Drink 1.5 Ltr'},
    ],
    'Pizzas': [
      {'name': "Pizza'Clock Special", 'price': 1050, 'description': 'Our signature special with chicken, cheese, and secret sauce'},
      {'name': 'Bonfire', 'price': 1050, 'description': 'Smoky BBQ chicken with onions and bell peppers'},
      {'name': 'Click On', 'price': 1050, 'description': 'Special blend of spicy chicken and premium cheese'},
      {'name': 'Super Supreme', 'price': 1150, 'description': 'Fully loaded with chicken, veggies, and extra cheese'},
      {'name': 'Supreme Delight', 'price': 1150, 'description': 'Delightful mix of chicken chunks and olives'},
      {'name': "Kera Le'Tistro", 'price': 1150, 'description': 'Exotic flavors with a unique sauce blend'},
      {'name': 'Chicken Supreme', 'price': 950, 'description': 'Classic chicken chunks with veggies'},
      {'name': 'Veggie Lover', 'price': 850, 'description': 'Loaded with fresh garden vegetables'},
      {'name': 'Chicken Tikka', 'price': 950, 'description': 'Traditional tikka chicken with onions'},
      {'name': 'Hot N Spicy', 'price': 950, 'description': 'Spicy chicken with jalapenos and red chili'},
      {'name': 'Fajita Sicilian', 'price': 950, 'description': 'Mexican style fajita chicken'},
      {'name': 'Euro', 'price': 1000, 'description': 'European inspired chicken and cheese blend'},
      {'name': 'Cheese Lover', 'price': 900, 'description': 'Extra heavy blend of premium cheeses'},
      {'name': 'Kabab Stuffed Crust', 'price': 1250, 'description': 'Delicious crust stuffed with juicy kebabs'},
      {'name': 'Cheese Stuffed Crust', 'price': 1250, 'description': 'Cheesy goodness inside the crust'},
      {'name': 'Chicken N Cheese Stuffed', 'price': 1300, 'description': 'Crust stuffed with chicken and cheese'},
      {'name': 'Gowny Crust', 'price': 1990, 'description': 'Only Large size available with premium toppings'},
    ],
    'Pasta': [
      {'name': 'Flaming Pesto', 'price': 500, 'description': 'Half/Full available'},
      {'name': 'Crunchy Pesto', 'price': 500, 'description': 'Half/Full available'},
      {'name': 'Kebabish Pasta', 'price': 500, 'description': 'Half/Full available'},
      {'name': 'Pesto', 'price': 500, 'description': 'Half/Full available'},
    ],
    'Beverages': [
      {'name': '500ml Drink', 'price': 130, 'description': 'Chilled beverage'},
      {'name': 'Tin Pack', 'price': 130, 'description': 'Can drink'},
      {'name': '1 Ltr Drink', 'price': 170, 'description': 'Family size'},
      {'name': '1.5 Ltr Drink', 'price': 240, 'description': 'Large bottle'},
      {'name': 'Mineral Water Small', 'price': 90, 'description': 'Small mineral water'},
      {'name': 'Mineral Water Large', 'price': 120, 'description': 'Large mineral water'},
    ],
    'Sauces': [
      {'name': 'Dip Sauce', 'price': 110, 'description': 'Classic dip sauce'},
      {'name': 'Thousand Island', 'price': 110, 'description': 'Thousand island dressing'},
      {'name': 'Mayo Mustard', 'price': 110, 'description': 'Mayo mustard sauce'},
    ],
    'Fun Square': [
      {'name': 'Fun Square Small', 'price': 850, 'description': 'Small square pizza with custom toppings'},
      {'name': 'Fun Square Medium', 'price': 1450, 'description': 'Medium square pizza with custom toppings'},
      {'name': 'Fun Square Large', 'price': 2100, 'description': 'Large square pizza with custom toppings'},
    ],
    'Kidco Club': [
      {'name': 'Kidco Meal 1', 'price': 499, 'description': 'Kidco Pizza, Nuggets, Fries, Juice'},
      {'name': 'Kidco Meal 2', 'price': 499, 'description': 'Kidco Burger, Nuggets, Fries, Juice'},
    ],
  };

  void _setActiveCategory(String category) {
    setState(() {
      _activeCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.text : Colors.black87;
    final backgroundColor = isDark ? AppColors.background : AppColors.backgroundLight;

    final bool isPOClock = (widget.restaurantName ?? '').toLowerCase().contains('pizza o clock');

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sticky header with back button, title, cart
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: isDark ? AppColors.background.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.card : Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                                color: textColor,
                                iconSize: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.restaurantName ?? 'Pizza Hub Vehari',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        // Cart icon with badge
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, child) {
                            final cartCount = cartProvider.itemCount;
                            return Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, RouteNames.cart);
                                  },
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 8)],
                                    ),
                                    child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                                  ),
                                ),
                                if (cartCount > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white : Colors.black87,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: backgroundColor, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$cartCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                toolbarHeight: 70,
                automaticallyImplyLeading: false,
              ),

              // Hero image section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA3Fyz3lArS2XLtUfdSEnRyxAW0XqvMrMkeuBAZEbQzD7u21qRIfi6dA9kdDA1nGiFNFk027X0RFWQYtsvRD1Cq59ceOk53-65gLZG50utgshPPOGqvkBfwQgcWSLrWyhO92OHiawiyA6RkWPL0UqHDPm8Gb6jghZz_8Gfa7FqTL5ygC-eshOICxSFUMcSFg7WctBUgH6ueOUd6t2R4eb_6Hc6L9SplHW8idwpbltzkMzFziXM6jz7WFhXA9lVfd50Z55ZQvjowLeg3',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Top Rated',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Trending',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Restaurant info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuB82WIov2K5mueR4BBI_Aor6wWRK2luoKhynDg_zrykUurPmOplEh-NEZE57V6Y-r4Bp6K0qdzBnh-m5XHWNAYdL7IDWU0mriePAUKPLD3Sk93y4TxAaj33kTirf-bWjmdlTlKfJt-jz3meNxLlox8vfqSKTqJp48MeCCIRBYcSUUY4uN_u3ZRgvmKiNyWodOzrg87QS2CUK8AeFGwpfR2hD89MvsW8_QTIpxh_pPkurnGs_gI6k2KwF50JtKtN4GOUevz_Ygjsaoy9',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Name, rating, time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.restaurantName ?? 'Pizza Hub Vehari',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, color: primary, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '4.5',
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '20-30 MINS',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Modern, clean, premium pizza hub serving artisanal wood-fired delicacies.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Sticky category tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryTabDelegate(
                  isDark: isDark,
                  primary: primary,
                  activeCategory: _activeCategory,
                  onCategoryTap: _setActiveCategory,
                  isPOClock: isPOClock,
                ),
              ),

              // Menu sections
              if (isPOClock)
                SliverToBoxAdapter(
                  child: _buildMenuSection(
                    context,
                    title: _activeCategory,
                    items: (_poClockMenu[_activeCategory] ?? []).asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final pizza = PizzaModel(
                        id: 'p_o_clock_${_activeCategory}_$index',
                        name: item['name'],
                        description: item['description'],
                        price: (item['price'] as int).toDouble(),
                        imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
                        restaurantId: widget.restaurantId ?? '',
                        restaurantName: widget.restaurantName ?? 'P.O Clock',
                        category: _activeCategory,
                        ingredients: [],
                        rating: 4.0 + (index % 10) * 0.1,
                        totalReviews: 10 + (index * 5),
                        isBestSeller: index < 2,
                      );
                      return _MenuItem(
                        pizza: pizza,
                        isPOClock: true,
                        onAdd: () {
                          // Allow "Pizzas", "Deals", "Pasta", and "Fun Square" to go to detail screen for customization
                          final needsCustomization = ['Pizzas', 'Deals', 'P.O Clock Special', 'Pasta', 'Fun Square'].contains(pizza.category);
                          if (needsCustomization) {
                            Navigator.pushNamed(
                              context,
                              RouteNames.pizzaDetail,
                              arguments: pizza,
                            );
                          } else {
                            final userId = context.read<AppAuthProvider>().user?.uid;
                            Provider.of<CartProvider>(context, listen: false).addToCart(pizza, userId: userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${pizza.name} added to cart')),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                )
              else
                FutureBuilder<List<PizzaModel>>(
                  future: widget.restaurantId != null
                      ? Provider.of<RestaurantProvider>(context, listen: false).getRestaurantMenu(widget.restaurantId!)
                      : Future.value([]),
                  builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No menu items found"),
                      )),
                    );
                  }

                  final menuItems = snapshot.data!;

                  return SliverToBoxAdapter(
                    child: _buildMenuSection(
                      context,
                      title: 'Menu',
                      items: menuItems.map((item) {
                        return _MenuItem(
                          pizza: item.restaurantName == null 
                            ? item.copyWith(restaurantName: widget.restaurantName) 
                            : item,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          // View Cart button sticky at bottom
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.itemCount == 0) return const SizedBox.shrink();
              
              final count = cartProvider.itemCount;
              final total = cartProvider.totalAmount;

              return Positioned(
                left: 16,
                right: 16,
                bottom: 30,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.cart);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '•',
                                  style: TextStyle(color: Colors.white54, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'VIEW CART',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs. $total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, {required String title, required List<_MenuItem> items}) {
    final primary = AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigator.pushNamed(context, RouteNames.restaurants);
                },
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => items[index],
          ),
        ],
      ),
    );
  }
}

class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final Color primary;
  final String activeCategory;
  final Function(String) onCategoryTap;
  final bool isPOClock;

  _CategoryTabDelegate({
    required this.isDark,
    required this.primary,
    required this.activeCategory,
    required this.onCategoryTap,
    this.isPOClock = false,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.background : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: isPOClock 
        ? [
          _categoryChip('Appetizer'),
          _categoryChip('P.O Clock Special'),
          _categoryChip('Deals'),
          _categoryChip('Pizzas'),
          _categoryChip('Pasta'),
          _categoryChip('Beverages'),
          _categoryChip('Sauces'),
          _categoryChip('Fun Square'),
          _categoryChip('Kidco Club'),
        ]
        : [
          _categoryChip('Medium Pizzas'),
          _categoryChip('XL Pizzas'),
          _categoryChip('Family Specials'),
          _categoryChip('Sides'),
          _categoryChip('Drinks'),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final bool isSelected = activeCategory == label;
    return InkWell(
      onTap: () => onCategoryTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : (isDark ? AppColors.card : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primary : (isDark ? AppColors.border : Colors.transparent)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppColors.subtle : Colors.grey.shade600),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(covariant _CategoryTabDelegate oldDelegate) {
    return oldDelegate.activeCategory != activeCategory;
  }
}

class _MenuItem extends StatelessWidget {
  final PizzaModel pizza;
  final VoidCallback? onAdd;
  final bool isPOClock;

  const _MenuItem({
    required this.pizza,
    this.onAdd,
    this.isPOClock = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.text : Colors.black87;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteNames.pizzaDetail,
          arguments: pizza,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(pizza.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pizza.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pizza.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.subtle : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${pizza.price}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                      InkWell(
                        onTap: isPOClock ? onAdd : () {
                          final userId = context.read<AppAuthProvider>().user?.uid;
                          context.read<CartProvider>().addToCart(pizza, userId: userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${pizza.name} added to cart'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


