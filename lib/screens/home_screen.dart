import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/route_names.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deals_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../models/pizza_model.dart';
import '../../services/location_service.dart';

import '../../widgets/common/custom_bottom_nav.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initData();
  }

  Future<void> _initData() async {
    final user = context.read<AppAuthProvider>().user;
    double? lat, lng;

    if (user != null) {
      final defaultAddr = await FirestoreService().getDefaultAddress(user.uid);
      if (defaultAddr != null) {
        lat = (defaultAddr['lat'] as num?)?.toDouble();
        lng = (defaultAddr['lng'] as num?)?.toDouble();
      }
    }

    if (!mounted) return;
    context.read<RestaurantProvider>().fetchRestaurants(userLat: lat, userLng: lng);
    context.read<DealsProvider>().fetchDeals();
    
    if (user != null) {
      context.read<OrderProvider>().fetchOrders(user.uid);
      context.read<NotificationProvider>().fetchNotifications(user.uid);
    }
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
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
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
                    child: Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        final unreadCount = notificationProvider.unreadCount;
                        if (unreadCount == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
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
    return InkWell(
      onTap: () => Navigator.pushNamed(context, RouteNames.addressManagement),
      child: Container(
        color: const Color(0xFF181818),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 14),
            const SizedBox(width: 5),
            const Text('Delivering to ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: Stream.fromFuture(context.read<AppAuthProvider>().user != null 
                  ? FirestoreService().getDefaultAddress(context.read<AppAuthProvider>().user!.uid)
                  : Future.value(null)),
                builder: (context, snapshot) {
                  final address = snapshot.data?['address'] ?? 'Select your location';
                  return Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w500),
                  );
                }
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 16),
          ],
        ),
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


