class FirestoreConstants {
  // Collections
  static const String users = 'users';
  static const String restaurants = 'restaurants';
  static const String orders = 'orders';
  static const String menu = 'menu';
  static const String cart = 'cart';
  static const String addresses = 'addresses';
  static const String notifications = 'notifications';
  static const String promotions = 'promotions';
  static const String deals = 'deals';
  static const String commissions = 'commissions';

  // Common Fields
  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String image = 'image';
  static const String category = 'category';
  static const String createdAt = 'createdAt';
  static const String rating = 'rating';
  static const String adminId = 'adminId';
  static const String zone = 'zone';
  static const String status = 'status';

  // Order Fields
  static const String userId = 'userId';
  static const String userName = 'userName';
  static const String items = 'items';
  static const String subtotal = 'subtotal';
  static const String deliveryFee = 'deliveryFee';
  static const String tax = 'tax';
  static const String totalAmount = 'totalAmount';
  static const String discountAmount = 'discountAmount';
  static const String promoCode = 'promoCode';
  static const String address = 'address';
  static const String paymentMethod = 'paymentMethod';
  static const String restaurantId = 'restaurantId';
  static const String restaurantName = 'restaurantName';
  static const String riderId = 'riderId';
  static const String riderName = 'riderName';
  static const String preparingAt = 'preparingAt';
  static const String onTheWayAt = 'onTheWayAt';
  static const String deliveredAt = 'deliveredAt';
  static const String cancelledAt = 'cancelledAt';
  static const String paidAt = 'paidAt';

  // Restaurant Fields
  static const String time = 'time';
  static const String delivery = 'delivery';
  static const String isOnDeal = 'isOnDeal';
  static const String commissionRate = 'commissionRate';

  // Menu Fields
  static const String price = 'price';
  static const String quantity = 'quantity';
  static const String isAvailable = 'isAvailable';
  static const String hasSizes = 'hasSizes';
  static const String isBestSeller = 'isBestSeller';

  // Deal Fields
  static const String title = 'title';
  static const String originalPrice = 'originalPrice';
  static const String discountedPrice = 'discountedPrice';
  static const String discountPercent = 'discountPercent';
  static const String tag = 'tag';
  static const String expiresAt = 'expiresAt';
  static const String imageUrl = 'imageUrl';

  // Notification Fields
  static const String body = 'body';
  static const String target = 'target';
  static const String type = 'type';

  // Promotion Fields
  static const String code = 'code';
  static const String discountType = 'discountType';
  static const String discountValue = 'discountValue';
  static const String redemptions = 'redemptions';
  static const String revenueGenerated = 'revenueGenerated';
  static const String newCustomers = 'newCustomers';
  static const String roi = 'roi';

  // User Fields
  static const String role = 'role';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String phoneNumber = 'phoneNumber';
  static const String photoUrl = 'photoUrl';
  static const String profileImage = 'profileImage';
  static const String displayName = 'displayName';
  static const String isBlocked = 'isBlocked';
  static const String blockedAt = 'blockedAt';
  static const String activeOrderId = 'activeOrderId';
  static const String currentLocation = 'currentLocation';
  static const String userOrdersCount = 'orders';
  static const String paid = 'paid';
  static const String year = 'year';
  static const String month = 'month';
  static const String totalOrders = 'totalOrders';
  static const String totalRevenue = 'totalRevenue';
  static const String totalCommission = 'totalCommission';
  static const String commissionAmount = 'commissionAmount';
  static const String isPaid = 'isPaid';
  static const String pendingOrders = 'pendingOrders';
  static const String totalRestaurants = 'totalRestaurants';
  static const String totalRiders = 'totalRiders';
  static const String totalCustomers = 'totalCustomers';
  static const String fcmToken = 'fcmToken';

  // Rating Fields
  static const String foodRating = 'foodRating';
  static const String riderRating = 'riderRating';
  static const String review = 'review';
  static const String ratingSubmitted = 'ratingSubmitted';
  static const String ratedAt = 'ratedAt';
  static const String totalRatingSum = 'totalRatingSum';
  static const String totalRatingCount = 'totalRatingCount';

  // Address Fields
  static const String isDefault = 'isDefault';

  // Order Statuses
  static const String statusPending = 'Pending';
  static const String statusPreparing = 'Preparing';
  static const String statusOnTheWay = 'On the way';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';

  // Notification Statuses
  static const String statusSent = 'Sent';
  static const String statusScheduled = 'Scheduled';
  static const String statusRunning = 'Running';
  static const String statusFailed = 'Failed';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleCustomer = 'customer';
  static const String roleRider = 'rider';

  // Rider Statuses
  static const String riderStatusAvailable = 'available';
  static const String riderStatusBusy = 'busy';
  static const String riderStatusOffline = 'offline';
}
