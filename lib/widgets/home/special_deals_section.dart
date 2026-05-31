import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/deal_model.dart';
import '../../models/pizza_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/deals_provider.dart';
import '../../routes/route_names.dart';

class SpecialDealsTodaySection extends StatefulWidget {
  const SpecialDealsTodaySection({super.key});

  @override
  State<SpecialDealsTodaySection> createState() =>
      _SpecialDealsTodaySectionState();
}

class _SpecialDealsTodaySectionState extends State<SpecialDealsTodaySection> {
  Timer? _timer;
  Duration _remaining = const Duration(hours: 5, minutes: 30);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        if (mounted) {
          setState(() => _remaining -= const Duration(seconds: 1));
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final dealsProvider = context.watch<DealsProvider>();

    if (dealsProvider.isLoading && dealsProvider.deals.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final deals = dealsProvider.deals;
    if (deals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header with countdown ─────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Special Deals Today',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              // Live countdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: primary.withAlpha(75)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: primary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${_pad(_remaining.inHours)}:${_pad(_remaining.inMinutes % 60)}:${_pad(_remaining.inSeconds % 60)}',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Deal Cards ────────────────────────────────────────
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            itemBuilder: (context, i) =>
                _DealCard(deal: deals[i], isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  final DealModel deal;
  final bool isDark;

  const _DealCard({required this.deal, required this.isDark});

  Color get _tagColor {
    switch (deal.tag) {
      case 'HOT':     return Colors.deepOrange;
      case 'LIMITED': return Colors.purple;
      case 'NEW':     return Colors.green;
      default:        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        RouteNames.restaurantDetail,
        arguments: deal.restaurantId,
      ),
      child: Container(
        width: 170,                          // slightly narrower
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,    // key fix
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.network(
                    deal.imageUrl,
                    width: double.infinity,
                    height: 95,              // reduced from 110
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 95,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${deal.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _tagColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deal.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8),   // reduced from 10
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deal.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rs ${deal.discountedPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Rs ${deal.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final pizza = PizzaModel(
                            id: deal.id,
                            name: deal.title,
                            description: deal.description,
                            imageUrl: deal.imageUrl,
                            price: deal.discountedPrice,
                            restaurantId: deal.restaurantId,
                            category: 'Deal',
                            ingredients: [],
                            rating: 4.8,
                            totalReviews: 120,
                            isBestSeller: true,
                          );
                          final userId = context.read<AppAuthProvider>().user?.uid;
                          context.read<CartProvider>().addToCart(pizza, userId: userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${deal.title} added to cart!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.pushNamed(context, RouteNames.cart);
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 26, // reduced from 30
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16),
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
