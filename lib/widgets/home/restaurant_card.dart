import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/pizza_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';

class RestaurantCard extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  String _selectedSize = 'All';
  List<PizzaModel> _menuItems = [];
  bool _isLoadingMenu = false;

  final List<String> _sizes = ['All', 'S', 'M', 'L', 'XL', 'F-Size'];

  StreamSubscription? _menuSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMenu();
  }

  void _listenToMenu() {
    setState(() => _isLoadingMenu = true);
    final provider = context.read<RestaurantProvider>();
    _menuSubscription = provider.getRestaurantMenuStream(widget.restaurant.id).listen(
      (items) {
        if (mounted) {
          setState(() {
            _menuItems = items;
            _isLoadingMenu = false;
          });
        }
      },
      onError: (e) {
        if (mounted) setState(() => _isLoadingMenu = false);
      },
    );
  }

  @override
  void dispose() {
    _menuSubscription?.cancel();
    super.dispose();
  }

  List<PizzaModel> get _filteredMenu {
    if (_selectedSize == 'All') return _menuItems;
    // For now, we'll filter by category as a proxy for size if size isn't explicitly in the model
    // or we can assume some mapping. 
    // Ideally, PizzaModel should have a 'size' field.
    return _menuItems.where((item) => item.category.toLowerCase() == _selectedSize.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Header (Image & Info)
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.restaurantDetail,
              arguments: widget.restaurant,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        widget.restaurant.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(height: 120, color: Colors.grey.shade300),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.restaurant.isOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            color: widget.restaurant.isOpen ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.restaurant.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.restaurant.address,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.primary, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              widget.restaurant.rating.toString(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Size Filters
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _sizes.length,
              itemBuilder: (context, index) {
                final size = _sizes[index];
                final isSelected = _selectedSize == size;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(size, style: const TextStyle(fontSize: 10)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSize = size);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),

          // Menu Items List
          Expanded(
            child: _isLoadingMenu
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : _filteredMenu.isEmpty
                    ? Center(
                        child: Text(
                          "No items for $_selectedSize",
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _filteredMenu.length.clamp(0, 3), // Show max 3 items
                        separatorBuilder: (context, index) => const Divider(height: 8),
                        itemBuilder: (context, index) {
                          final item = _filteredMenu[index];
                          return InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.pizzaDetail,
                              arguments: item,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Rs. ${item.price.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
