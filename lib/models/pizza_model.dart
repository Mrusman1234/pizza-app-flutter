class PizzaModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final Map<String, double>? prices;
  final List<AddonModel>? addons;
  final String restaurantId;
  final String? restaurantName;
  final String category;
  final List<String> ingredients;
  final bool isAvailable;
  final double rating;
  final int totalReviews;
  final bool isBestSeller;

  PizzaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.prices,
    this.addons,
    required this.restaurantId,
    this.restaurantName,
    required this.category,
    required this.ingredients,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isBestSeller = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'prices': prices,
      'addons': addons?.map((e) => e.toMap()).toList(),
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'category': category,
      'ingredients': ingredients,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalReviews': totalReviews,
      'isBestSeller': isBestSeller,
    };
  }

  factory PizzaModel.fromMap(Map<String, dynamic> map) {
    Map<String, double>? pricesMap;
    if (map['prices'] != null) {
      pricesMap = (map['prices'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    return PizzaModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num? ?? 0.0).toDouble(),
      prices: pricesMap,
      addons: (map['addons'] as List?)?.map((e) => AddonModel.fromMap(e)).toList(),
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'],
      category: map['category'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] as num? ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isBestSeller: map['isBestSeller'] ?? false,
    );
  }

  PizzaModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    Map<String, double>? prices,
    List<AddonModel>? addons,
    String? restaurantId,
    String? restaurantName,
    String? category,
    List<String>? ingredients,
    bool? isAvailable,
    double? rating,
    int? totalReviews,
    bool? isBestSeller,
  }) {
    return PizzaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      prices: prices ?? this.prices,
      addons: addons ?? this.addons,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isBestSeller: isBestSeller ?? this.isBestSeller,
    );
  }
}

class AddonModel {
  final String name;
  final double price;
  final Map<String, double>? priceBySize;

  AddonModel({required this.name, required this.price, this.priceBySize});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'priceBySize': priceBySize,
    };
  }

  factory AddonModel.fromMap(Map<String, dynamic> map) {
    return AddonModel(
      name: map['name'] ?? '',
      price: (map['price'] as num? ?? 0.0).toDouble(),
      priceBySize: (map['priceBySize'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }
}
