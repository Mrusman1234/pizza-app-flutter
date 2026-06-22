import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_admin_model.dart';
import '../services/restaurant_admin_service.dart';
import '../core/constants/firestore_constants.dart';

class RestaurantAdminProvider with ChangeNotifier {
  final RestaurantAdminService _service;
  final _db = FirebaseFirestore.instance;

  RestaurantAdminProvider(this._service);

  RestaurantAdminModel? _adminModel;
  bool _isLoading = false;
  String? _error;

  // ── Listeners ─────────────────────────────────────────────────────────────
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _menuSubscription;

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

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _menuSubscription?.cancel();
    super.dispose();
  }

  // ── Load admin after login ────────────────────────────────────────────────
  Future<void> loadAdmin(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getRestaurantAdmin(uid);
      _adminModel = data != null ? RestaurantAdminModel.fromMap(data) : null;
      if (_adminModel != null) {
        _startLiveStats();
        await _fetchTrends();
        await _fetchTopSellingItems();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('RestaurantAdminProvider.loadAdmin error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts real-time listeners for dashboard stats to avoid manual refresh
  void _startLiveStats() {
    if (_adminModel == null) return;
    final restId = _adminModel!.assignedRestaurantId;
    
    _ordersSubscription?.cancel();
    _menuSubscription?.cancel();

    // Listen to ALL orders for this restaurant to calculate real-time stats
    _ordersSubscription = _db
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.restaurantId, isEqualTo: restId)
        .snapshots()
        .listen((snapshot) {
      _calculateStatsFromSnapshot(snapshot);
      notifyListeners();
    }, onError: (e) {
      debugPrint('RestaurantAdminProvider: live stats error: $e');
    });

    // Also count menu items
    _menuSubscription = _db.collection(FirestoreConstants.restaurants)
        .doc(restId)
        .collection(FirestoreConstants.menu)
        .snapshots()
        .listen((snap) {
          _menuItemCount = snap.docs.length;
          notifyListeners();
        }, onError: (e) {
          debugPrint('RestaurantAdminProvider: menu listener error: $e');
        });
  }

  void _calculateStatsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    int todayCount = 0;
    double todayRev = 0;
    int pendingCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data[FirestoreConstants.status];
      final createdAt = (data[FirestoreConstants.createdAt] as Timestamp?)?.toDate();
      final amount = (data[FirestoreConstants.totalAmount] as num?)?.toDouble() ?? 0;

      if (status == FirestoreConstants.statusPending) {
        pendingCount++;
      }

      if (createdAt != null && createdAt.isAfter(startOfDay)) {
        todayCount++;
        todayRev += amount;
      }
    }

    _todayOrdersCount = todayCount;
    _todayRevenue = todayRev;
    _pendingOrdersCount = pendingCount;
  }

  /// One-time fetch for trends (since they change less frequently)
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

  // ── Stream Caching ───────────────────────────────────────────────────────
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>> _orderStreams = {};
  Stream<QuerySnapshot<Map<String, dynamic>>>? _menuStream;

  /// Real-time stream of orders for the admin's restaurant.
  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream({String? statusFilter}) {
    if (_adminModel == null) return const Stream.empty();
    
    final filterKey = statusFilter ?? 'All';
    if (_orderStreams.containsKey(filterKey)) return _orderStreams[filterKey]!;

    var query = _db
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.restaurantId, isEqualTo: _adminModel!.assignedRestaurantId)
        .orderBy(FirestoreConstants.createdAt, descending: true)
        .limit(50);

    if (statusFilter != null && statusFilter != 'All') {
      query = query.where(FirestoreConstants.status, isEqualTo: statusFilter);
    }
    
    _orderStreams[filterKey] = query.snapshots().asBroadcastStream();
    return _orderStreams[filterKey]!;
  }

  /// Real-time stream of menu items for the admin's restaurant.
  Stream<QuerySnapshot<Map<String, dynamic>>> menuStream() {
    if (_adminModel == null) return const Stream.empty();
    if (_menuStream != null) return _menuStream!;

    _menuStream = _db
        .collection(FirestoreConstants.restaurants)
        .doc(_adminModel!.assignedRestaurantId)
        .collection(FirestoreConstants.menu)
        .orderBy(FirestoreConstants.name)
        .snapshots()
        .asBroadcastStream();
        
    return _menuStream!;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _restaurantStream;

  /// Real-time stream of the current restaurant's document
  Stream<DocumentSnapshot<Map<String, dynamic>>> restaurantStream(String restId) {
    if (restId.isEmpty) return const Stream.empty();
    if (_restaurantStream != null) return _restaurantStream!;

    _restaurantStream = _db
        .collection(FirestoreConstants.restaurants)
        .doc(restId)
        .snapshots()
        .asBroadcastStream();
        
    return _restaurantStream!;
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
    _ordersSubscription?.cancel();
    _menuSubscription?.cancel();
    _orderStreams.clear();
    _menuStream = null;
    _restaurantStream = null;
    notifyListeners();
  }

  /// Refresh trends and top items (live stats update automatically)
  Future<void> refresh() async {
    await _fetchTrends();
    await _fetchTopSellingItems();
    notifyListeners();
  }
}
