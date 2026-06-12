import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_admin_model.dart';
import '../services/restaurant_admin_service.dart';
import '../core/constants/firestore_constants.dart';

class RestaurantAdminProvider with ChangeNotifier {
  final RestaurantAdminService _service = RestaurantAdminService();
  final _db = FirebaseFirestore.instance;

  RestaurantAdminModel? _adminModel;
  bool _isLoading = false;
  String? _error;

  // ── Live stats ────────────────────────────────────────────────────────────
  int _todayOrdersCount = 0;
  double _todayRevenue = 0;
  int _pendingOrdersCount = 0;
  int _menuItemCount = 0;

  // ── Trend data (Last 7 days) ─────────────────────────────────────────────
  List<double> _revenueTrend = [];
  List<int> _orderTrend = [];
  List<String> _trendLabels = [];
  List<Map<String, dynamic>> _topSellingItems = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  RestaurantAdminModel? get adminModel => _adminModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _adminModel != null;

  int get todayOrdersCount => _todayOrdersCount;
  double get todayRevenue => _todayRevenue;
  int get pendingOrdersCount => _pendingOrdersCount;
  int get menuItemCount => _menuItemCount;

  List<double> get revenueTrend => _revenueTrend;
  List<int> get orderTrend => _orderTrend;
  List<String> get trendLabels => _trendLabels;
  List<Map<String, dynamic>> get topSellingItems => _topSellingItems;

  String get restaurantId => _adminModel?.assignedRestaurantId ?? '';
  String get restaurantName => _adminModel?.assignedRestaurantName ?? '';

  // ── Load admin after login ────────────────────────────────────────────────
  Future<void> loadAdmin(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adminModel = await _service.getRestaurantAdmin(uid);
      if (_adminModel != null) {
        await _fetchStats();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('RestaurantAdminProvider.loadAdmin error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch today's order count, revenue, pending count, and menu item count.
  Future<void> _fetchStats() async {
    if (_adminModel == null) return;
    final restId = _adminModel!.assignedRestaurantId;

    // Today's date range
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // Today's orders
      final todaySnap = await _db
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.restaurantId, isEqualTo: restId)
          .where(FirestoreConstants.createdAt, isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where(FirestoreConstants.createdAt, isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      _todayOrdersCount = todaySnap.docs.length;
      _todayRevenue = todaySnap.docs.fold<double>(
        0,
        (acc, doc) => acc + ((doc.data()[FirestoreConstants.totalAmount] as num?)?.toDouble() ?? 0),
      );

      // Pending orders
      final pendingSnap = await _db
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.restaurantId, isEqualTo: restId)
          .where(FirestoreConstants.status, isEqualTo: FirestoreConstants.statusPending)
          .get();
      _pendingOrdersCount = pendingSnap.docs.length;

      // Menu items
      final menuSnap = await _db
          .collection(FirestoreConstants.restaurants)
          .doc(restId)
          .collection(FirestoreConstants.menu)
          .get();
      _menuItemCount = menuSnap.docs.length;

      await _fetchTrends();
      await _fetchTopSellingItems();

      notifyListeners();
    } catch (e) {
      debugPrint('RestaurantAdminProvider._fetchStats error: $e');
    }
  }

  Future<void> _fetchTrends() async {
    if (_adminModel == null) return;
    final restId = _adminModel!.assignedRestaurantId;

    _revenueTrend = List.filled(7, 0.0);
    _orderTrend = List.filled(7, 0);
    _trendLabels = [];

    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      _trendLabels.add('${date.day}/${date.month}');
    }

    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    try {
      final snap = await _db
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.restaurantId, isEqualTo: restId)
          .where(FirestoreConstants.createdAt, isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final createdAt = data[FirestoreConstants.createdAt] as Timestamp?;
        if (createdAt == null) continue;

        final date = createdAt.toDate();
        final diff = now.difference(date).inDays;
        if (diff >= 0 && diff < 7) {
          final index = 6 - diff;
          _orderTrend[index]++;
          _revenueTrend[index] += (data[FirestoreConstants.totalAmount] as num?)?.toDouble() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('RestaurantAdminProvider._fetchTrends error: $e');
    }
  }

  Future<void> _fetchTopSellingItems() async {
    if (_adminModel == null) return;
    final restId = _adminModel!.assignedRestaurantId;

    try {
      final snap = await _db
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.restaurantId, isEqualTo: restId)
          .where(FirestoreConstants.status, isEqualTo: FirestoreConstants.statusDelivered)
          .limit(100)
          .get();

      Map<String, int> productCounts = {};
      Map<String, String> productNames = {};

      for (var doc in snap.docs) {
        final items = doc.data()[FirestoreConstants.items] as List?;
        if (items != null) {
          for (var item in items) {
            final name = item[FirestoreConstants.name] as String?;
            if (name != null) {
              final String id = item['pizzaId'] as String? ?? name;
              productCounts[id] = (productCounts[id] ?? 0) + (item[FirestoreConstants.quantity] as int? ?? 1);
              productNames[id] = name;
            }
          }
        }
      }

      var sortedKeys = productCounts.keys.toList()
        ..sort((a, b) => productCounts[b]!.compareTo(productCounts[a]!));

      _topSellingItems = sortedKeys.take(5).map((id) => {
        'name': productNames[id] ?? 'Unknown',
        'count': productCounts[id] ?? 0,
      }).toList();
    } catch (e) {
      debugPrint('RestaurantAdminProvider._fetchTopSellingItems error: $e');
    }
  }

  /// Real-time stream of orders for the admin's restaurant.
  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream({String? statusFilter}) {
    if (_adminModel == null) {
      return const Stream.empty();
    }
    var query = _db
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.restaurantId, isEqualTo: _adminModel!.assignedRestaurantId)
        .orderBy(FirestoreConstants.createdAt, descending: true)
        .limit(50);

    if (statusFilter != null && statusFilter != 'All') {
      query = _db
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.restaurantId, isEqualTo: _adminModel!.assignedRestaurantId)
          .where(FirestoreConstants.status, isEqualTo: statusFilter)
          .orderBy(FirestoreConstants.createdAt, descending: true)
          .limit(50);
    }
    return query.snapshots();
  }

  /// Real-time stream of menu items for the admin's restaurant.
  Stream<QuerySnapshot<Map<String, dynamic>>> menuStream() {
    if (_adminModel == null) return const Stream.empty();
    return _db
        .collection(FirestoreConstants.restaurants)
        .doc(_adminModel!.assignedRestaurantId)
        .collection(FirestoreConstants.menu)
        .orderBy(FirestoreConstants.name)
        .snapshots();
  }

  /// Real-time stream of audit logs for the admin's restaurant.
  Stream<QuerySnapshot<Map<String, dynamic>>> auditLogsStream() {
    if (_adminModel == null) return const Stream.empty();
    return _db
        .collection('audit_logs')
        .where('restaurantId', isEqualTo: _adminModel!.assignedRestaurantId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  void clear() {
    _adminModel = null;
    _todayOrdersCount = 0;
    _todayRevenue = 0;
    _pendingOrdersCount = 0;
    _menuItemCount = 0;
    notifyListeners();
  }

  /// Refresh stats (call after any mutation).
  Future<void> refresh() => _fetchStats();
}
