import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../models/pizza_model.dart';
import '../models/restaurant_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_provider.dart';
import '../routes/route_names.dart';
import '../widgets/shimmer_loader.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;
  const RestaurantMenuScreen({super.key, this.restaurantId, this.restaurantName});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String _activeCategory = 'Appetizer';

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

    final String nameLower = (widget.restaurantName ?? '').toLowerCase();
    final bool isPOClock = nameLower.contains('pizza o clock');
    final bool isCookooz = nameLower.contains('cookooz') || nameLower.contains('cookoo\'z');

    // DEBUG LOGS
    debugPrint('🏪 Opening RestaurantMenuScreen for: ${widget.restaurantName}');
    debugPrint('🆔 Restaurant ID: "${widget.restaurantId}"');

    if (widget.restaurantId == null || widget.restaurantId!.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text("Error: Missing Restaurant ID", style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return StreamBuilder<RestaurantModel?>(
      stream: Provider.of<RestaurantProvider>(context, listen: false).getRestaurantStream(widget.restaurantId!),
      builder: (context, restaurantSnapshot) {
        final restaurant = restaurantSnapshot.data;
        final isBusy = restaurant?.isBusy ?? false;
        final isClosed = restaurant != null && !restaurant.isOperatingNow;

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

                  // Busy Mode Banner
                  if (isBusy)
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        color: Colors.orange.shade800,
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Restaurant is currently busy. Online ordering is temporarily disabled.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: restaurant?.imageUrl ?? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const ShimmerLoader(width: double.infinity, height: double.infinity, borderRadius: 0),
                              errorWidget: (context, url, error) => Container(color: Colors.grey.shade800),
                            ),
                            if (isClosed)
                              Container(
                                color: Colors.black.withValues(alpha: 0.6),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer_off_outlined, color: Colors.white, size: 48),
                                      const SizedBox(height: 12),
                                      Text(
                                        isBusy ? 'BUSY' : 'CLOSED NOW',
                                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                                      ),
                                      const Text('Check operating hours below', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
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
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: restaurant?.imageUrl ?? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const ShimmerLoader(width: 80, height: 80, borderRadius: 16),
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
                                            restaurant?.rating.toString() ?? '4.5',
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
                  isCookooz: isCookooz,
                ),
              ),

              // Menu sections
              FutureBuilder<List<PizzaModel>>(
                future: widget.restaurantId != null
                    ? Provider.of<RestaurantProvider>(context, listen: false).getRestaurantMenu(widget.restaurantId!)
                    : Future.value([]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: List.generate(4, (index) => const MenuItemShimmer()),
                        ),
                      ),
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
                  final categories = menuItems.map((e) => e.category).toSet().toList();
                  if (_activeCategory == 'Appetizer' && !categories.contains('Appetizer') && categories.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _activeCategory = categories.first);
                    });
                  }

                  final filteredItems = menuItems.where((item) => item.category == _activeCategory).toList();

                  return SliverToBoxAdapter(
                    child: _buildMenuSection(
                      context,
                      title: _activeCategory,
                      items: filteredItems.map((item) {
                        return _MenuItem(
                          pizza: item.restaurantName == null 
                            ? item.copyWith(restaurantName: widget.restaurantName) 
                            : item,
                          isBusy: isClosed || isBusy,
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
              if (cartProvider.itemCount == 0 || isBusy || isClosed) return const SizedBox.shrink();
              
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
            },
          ),
        ],
      ),
    );
      },
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
  final bool isCookooz;

  _CategoryTabDelegate({
    required this.isDark,
    required this.primary,
    required this.activeCategory,
    required this.onCategoryTap,
    this.isPOClock = false,
    this.isCookooz = false,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    List<String> categories;
    if (isPOClock) {
      categories = [
        'Appetizer', 'P.O Clock Special', 'Deals', 'Pizzas', 'Pasta', 'Beverages', 'Sauces', 'Fun Square', 'Kidco Club'
      ];
    } else if (isCookooz) {
      categories = [
        'Pizza (Traditional)', 'Pizza (Premium)', 'Pizza (Signature)', 'Mega Deals', 'Wraps', 'Specialities', 'Fries', 'Side Orders', 'Burger', 'Burger Deals', 'Shakes & Desserts', 'Hot Bar', 'Drinks & Beverages'
      ];
    } else {
      categories = ['Medium Pizzas', 'XL Pizzas', 'Family Specials', 'Sides', 'Drinks'];
    }

    return Container(
      color: isDark ? AppColors.background : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((c) => _categoryChip(c)).toList(),
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
  final bool isBusy;

  const _MenuItem({
    required this.pizza,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.text : Colors.black87;

    return InkWell(
      onTap: isBusy ? null : () {
        Navigator.pushNamed(
          context,
          RouteNames.pizzaDetail,
          arguments: pizza,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: isBusy ? 0.6 : 1.0,
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
                          onTap: isBusy ? null : () {
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
                              color: isBusy ? Colors.grey : primary,
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
      ),
    );
  }
}


