import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/deals_provider.dart';
import '../../models/deal_model.dart';
import '../../routes/route_names.dart';

class HotDealsBanner extends StatefulWidget {
  const HotDealsBanner({super.key});

  @override
  State<HotDealsBanner> createState() => _HotDealsBannerState();
}

class _HotDealsBannerState extends State<HotDealsBanner> {
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final deals = context.read<DealsProvider>().deals.where((d) => d.tag == 'HOT').toList();
      if (_controller.hasClients && deals.isNotEmpty) {
        final next = (_current + 1) % deals.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealsProvider = context.watch<DealsProvider>();
    final hotDeals = dealsProvider.deals.where((d) => d.tag == 'HOT').toList();

    if (dealsProvider.isLoading && hotDeals.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (hotDeals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.whatshot_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Hot Deals',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Auto-scrolling banners
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: hotDeals.length,
            itemBuilder: (context, i) =>
                _BannerCard(deal: hotDeals[i]),
          ),
        ),
        const SizedBox(height: 10),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            hotDeals.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i
                    ? AppColors.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final DealModel deal;
  const _BannerCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    // Generate colors based on deal index or something for variety if not in model
    final Color color1 = const Color(0xFFCC1B1B);
    final Color color2 = const Color(0xFF8B0000);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color1.withAlpha(102),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background image (right side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 140,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18)),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [color1, Colors.transparent],
                ).createShader(bounds),
                blendMode: BlendMode.dstOut,
                child: Image.network(
                  deal.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),

          // Text content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🔥 Hot Deal!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deal.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context, 
                    RouteNames.restaurantDetail,
                    arguments: deal.restaurantId,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Order Now',
                      style: TextStyle(
                        color: color1,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
