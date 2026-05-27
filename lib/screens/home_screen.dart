import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/route_names.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/deals_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/pizza_model.dart';

// Import modular widgets
import '../../widgets/home/promotional_banner.dart';
import '../../widgets/home/order_tracking_card.dart';
import '../../widgets/home/hot_deals_banner.dart';
import '../../widgets/home/popular_today_section.dart';
import '../../widgets/home/special_deals_section.dart';
import '../../widgets/home/voucher_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  Stream<List<PizzaModel>>? _searchStream;
  Timer? _debounce;
  bool _isSearching = false;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Fetch restaurants on init to keep provider state updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchRestaurants();
      context.read<DealsProvider>().fetchDeals();
      final user = context.read<AppAuthProvider>().user;
      if (user != null) {
        context.read<OrderProvider>().fetchOrders(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        setState(() {
          _isSearching = true;
          _searchStream = context.read<RestaurantProvider>().searchPizzas(_searchController.text);
        });
      } else {
        setState(() {
          _isSearching = false;
          _searchStream = null;
        });
      }
    });
  }

  void _navigateToPizzaDetail(PizzaModel pizza) {
    _searchFocusNode.unfocus();
    Navigator.pushNamed(
      context,
      RouteNames.pizzaDetail,
      arguments: pizza,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLocationBar(),
            Expanded(
              child: Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: PromotionalBanner()),
                      SliverToBoxAdapter(child: _buildCategories()),
                      const SliverToBoxAdapter(child: OrderTrackingCard()),
                      const SliverToBoxAdapter(child: VoucherBanner()),
                      
                      const SliverPadding(
                        padding: EdgeInsets.only(top: 20),
                        sliver: SliverToBoxAdapter(child: HotDealsBanner()),
                      ),
                      
                      const SliverPadding(
                        padding: EdgeInsets.only(top: 24),
                        sliver: SliverToBoxAdapter(child: SpecialDealsTodaySection()),
                      ),

                      const SliverPadding(
                        padding: EdgeInsets.only(top: 24, bottom: 100),
                        sliver: SliverToBoxAdapter(
                          child: PopularTodaySection(
                            selectedCategory: 'All',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isSearching) _buildSearchResults(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    final categories = [
      {'name': 'All', 'icon': Icons.all_inclusive},
      {'name': 'Pizzas', 'icon': Icons.local_pizza},
      {'name': 'Burgers', 'icon': Icons.lunch_dining},
      {'name': 'Deals', 'icon': Icons.local_offer},
      {'name': 'Drinks', 'icon': Icons.local_drink},
    ];

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
               Navigator.pushNamed(
                context, 
                RouteNames.restaurants,
                arguments: cat['name'] == 'All' ? null : cat['name'],
              );
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.local_pizza, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pizza O Clock', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500)),
                  Text('VEHARI OFFICIAL', style: TextStyle(color: AppColors.primary, fontSize: 9, letterSpacing: 1.2)),
                ],
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.subtle, size: 18),
                    ),
                  ),
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card, 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Text('EN', style: TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.bold)),
                    Icon(Icons.keyboard_arrow_down, color: AppColors.subtle, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(13)),
            child: Row(
              children: [
                const SizedBox(width: 13),
                const Icon(Icons.search, color: AppColors.muted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search pizzas, deals…',
                      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.muted),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    ),
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(7),
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.tune, color: Colors.white, size: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LOCATION BAR ─────────────────────────────────────────────────────────
  Widget _buildLocationBar() {
    return Container(
      color: const Color(0xFF181818),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 14),
          SizedBox(width: 5),
          Text('Delivering to ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          Text('Main Multan Road, Vehari',
              style: TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w500)),
          Spacer(),
          Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 16),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Home', 0, () {}),
              _navItem(Icons.storefront_outlined,   'Hubs',    1, () => Navigator.pushNamed(context, RouteNames.restaurants)),
              // Cart FAB
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, RouteNames.cart),
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Stack(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 3),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: Colors.white, size: 22),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            if (cart.itemCount == 0) return const SizedBox.shrink();
                            return Container(
                              width: 17, height: 17,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Center(
                                child: Text(cart.itemCount.toString(),
                                    style: const TextStyle(color: AppColors.primary, fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _navItem(Icons.receipt_long_outlined, 'Orders',  3, () => Navigator.pushNamed(context, RouteNames.myOrders)),
              _navItem(Icons.person_outline,        'Profile', 4, () => Navigator.pushNamed(context, RouteNames.profile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _navIndex == index ? AppColors.primary : AppColors.muted, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: _navIndex == index ? AppColors.primary : AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: StreamBuilder<List<PizzaModel>>(
        stream: _searchStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ));
          }
          
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            ));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.only(top: 100.0),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text('No pizzas found matching your search', style: TextStyle(color: AppColors.subtle)),
                ],
              ),
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final pizza = results[index];
              return _buildSearchItem(pizza);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchItem(PizzaModel pizza) {
    return InkWell(
      onTap: () => _navigateToPizzaDetail(pizza),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                pizza.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60, height: 60, color: AppColors.card2,
                  child: const Icon(Icons.local_pizza, color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pizza.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(pizza.category, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${pizza.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(pizza.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


