class RestaurantModel {
  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final double rating;
  final String ownerId;
  final bool isOpen;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.ownerId,
    this.isOpen = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'address': address,
      'rating': rating,
      'ownerId': ownerId,
      'isOpen': isOpen,
    };
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    double parseRating(dynamic r) {
      if (r == null) return 0.0;
      if (r is double) return r;
      if (r is int) return r.toDouble();
      if (r is String) return double.tryParse(r) ?? 0.0;
      return 0.0;
    }

    return RestaurantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['image'] ?? map['imageUrl'] ?? '',
      address: map['address'] ?? map['description'] ?? '',
      rating: parseRating(map['rating']),
      ownerId: map['ownerId'] ?? '',
      isOpen: map['isOpen'] ?? true,
    );
  }
}
