class DealModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercent;
  final String tag; // 'HOT' | 'NEW' | 'LIMITED'
  final DateTime expiresAt;
  final String restaurantId;
  final String restaurantName;

  const DealModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.tag,
    required this.expiresAt,
    required this.restaurantId,
    required this.restaurantName,
  });

  factory DealModel.fromMap(Map<String, dynamic> m, String docId) {
    return DealModel(
      id: docId,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      imageUrl: m['imageUrl'] ?? '',
      originalPrice: (m['originalPrice'] as num?)?.toDouble() ?? 0,
      discountedPrice: (m['discountedPrice'] as num?)?.toDouble() ?? 0,
      discountPercent: (m['discountPercent'] as num?)?.toInt() ?? 0,
      tag: m['tag'] ?? 'HOT',
      expiresAt: (m['expiresAt'] as dynamic)?.toDate() ?? DateTime.now(),
      restaurantId: m['restaurantId'] ?? '',
      restaurantName: m['restaurantName'] ?? '',
    );
  }

  // Mock data for testing
  static List<DealModel> getMockDeals() => [
        DealModel(
          id: '1',
          title: 'Mega Deal Box',
          description: '2 Large Pizzas + 2 Drinks',
          imageUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
          originalPrice: 2400,
          discountedPrice: 1499,
          discountPercent: 38,
          tag: 'HOT',
          expiresAt: DateTime.now().add(const Duration(hours: 5)),
          restaurantId: '1',
          restaurantName: 'Cookoz',
        ),
        DealModel(
          id: '2',
          title: 'Family Feast',
          description: '3 Medium Pizzas + Garlic Bread',
          imageUrl:
              'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
          originalPrice: 3000,
          discountedPrice: 1999,
          discountPercent: 33,
          tag: 'LIMITED',
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          restaurantId: '2',
          restaurantName: 'Jaffaz',
        ),
        DealModel(
          id: '3',
          title: 'Solo Special',
          description: '1 Small Pizza + 1 Drink + Fries',
          imageUrl:
              'https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=400',
          originalPrice: 900,
          discountedPrice: 599,
          discountPercent: 33,
          tag: 'NEW',
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          restaurantId: '1',
          restaurantName: 'Cookoz',
        ),
      ];
}
