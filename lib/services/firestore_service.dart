import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_constants.dart';
import '../models/chat_model.dart';
import '../models/cart_model.dart';
import 'audit_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuditService _audit = AuditService();

  Stream<List<Map<String, dynamic>>> getRestaurants({String? searchQuery, String? filter, String? adminId, String? restaurantId}) {
    Query query = _db.collection(FirestoreConstants.restaurants);

    if (adminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }
    
    if (restaurantId != null) {
      // Direct isolation for Restaurant Admins
      query = query.where(FieldPath.documentId, isEqualTo: restaurantId);
    }

    if (filter == 'Rating 4.0+') {
      query = query.where(FirestoreConstants.rating, isGreaterThanOrEqualTo: '4.0');
    } else if (filter == 'Free Delivery') {
      query = query.where(FirestoreConstants.delivery, isEqualTo: 'Free Delivery');
    } else if (filter == 'Deals') {
      query = query.where(FirestoreConstants.isOnDeal, isEqualTo: true);
    } else if (filter == 'Drinks') {
      query = query.where(FirestoreConstants.category, isEqualTo: 'Drinks');
    }

    return query.snapshots().map((snapshot) {
      List<Map<String, dynamic>> restaurants = snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                FirestoreConstants.id: doc.id,
              })
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        restaurants = restaurants.where((r) {
          final name = (r[FirestoreConstants.name] ?? '').toString().toLowerCase();
          final description = (r[FirestoreConstants.description] ?? '').toString().toLowerCase();
          return name.contains(searchLower) || description.contains(searchLower);
        }).toList();
      }

      if (filter == 'Under 30 mins') {
        restaurants = restaurants.where((r) {
          final time = (r[FirestoreConstants.time] ?? '').toString();
          final matches = RegExp(r'(\d+)').allMatches(time).map((m) => int.parse(m.group(0)!)).toList();
          if (matches.isNotEmpty) {
            return matches.last <= 30;
          }
          return false;
        }).toList();
      }

      return restaurants;
    });
  }

  Stream<List<Map<String, dynamic>>> getCart(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection(FirestoreConstants.users)
        .doc(userId)
        .collection(FirestoreConstants.cart)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  FirestoreConstants.id: doc.id,
                })
            .toList());
  }

  Future<void> addToCart(String userId, Map<String, dynamic> item) async {
    final cartRef = _db.collection(FirestoreConstants.users).doc(userId).collection(FirestoreConstants.cart);
    final existingItems = await cartRef.where(FirestoreConstants.name, isEqualTo: item[FirestoreConstants.name]).get();

    if (existingItems.docs.isNotEmpty) {
      final docId = existingItems.docs.first.id;
      final data = existingItems.docs.first.data();
      final currentQuantity = data[FirestoreConstants.quantity] ?? 0;
      await cartRef.doc(docId).update({
        FirestoreConstants.quantity: currentQuantity + (item[FirestoreConstants.quantity] ?? 1),
      });
    } else {
      await cartRef.add(item);
    }
  }

  Future<void> updateCartItemQuantity(String userId, String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(userId, itemId);
    } else {
      await _db
          .collection(FirestoreConstants.users)
          .doc(userId)
          .collection(FirestoreConstants.cart)
          .doc(itemId)
          .update({FirestoreConstants.quantity: newQuantity});
    }
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    await _db
        .collection(FirestoreConstants.users)
        .doc(userId)
        .collection(FirestoreConstants.cart)
        .doc(itemId)
        .delete();
  }

  Future<void> clearCart(String userId) async {
    final cartRef = _db.collection(FirestoreConstants.users).doc(userId).collection(FirestoreConstants.cart);
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<Map<String, dynamic>>> getMenuItems(String restaurantId) {
    if (restaurantId.isEmpty) {
      debugPrint('❌ Error: getMenuItems called with empty restaurantId');
      return Stream.value([]);
    }
    return _db
        .collection(FirestoreConstants.restaurants)
        .doc(restaurantId)
        .collection(FirestoreConstants.menu)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  FirestoreConstants.id: doc.id,
                  FirestoreConstants.restaurantId: restaurantId,
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getAllMenuItems() {
    return _db.collectionGroup(FirestoreConstants.menu).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final parentId = doc.reference.parent.parent?.id ?? '';
        
        if (parentId.isEmpty) {
          debugPrint('⚠️ Warning: Found menu item ${doc.id} without parent restaurant ID');
        }

        return {
          ...data,
          FirestoreConstants.id: doc.id,
          FirestoreConstants.restaurantId: parentId,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> searchMenuItems(String query) {
    if (query.isEmpty) return Stream.value([]);

    final searchLower = query.toLowerCase();

    return _db.collectionGroup(FirestoreConstants.menu).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final parentId = doc.reference.parent.parent?.id ?? '';
            
            if (parentId.isEmpty) {
              debugPrint('⚠️ Warning: Search result ${doc.id} has empty parent restaurant ID');
            }

            return {
              ...data,
              FirestoreConstants.id: doc.id,
              FirestoreConstants.restaurantId: parentId,
            };
          })
          .where((item) {
            final name = (item[FirestoreConstants.name] ?? '').toString().toLowerCase();
            return name.contains(searchLower);
          })
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getDeals() {
    return _db.collection(FirestoreConstants.deals).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                FirestoreConstants.id: doc.id,
              })
          .toList();
    });
  }

  Future<void> updateRiderStatus(String riderId, String status) async {
    if (riderId.isEmpty) return;
    await _db.collection(FirestoreConstants.users).doc(riderId).update({
      FirestoreConstants.status: status,
    });
  }

  Future<void> completeOrder(String orderId, String riderId) async {
    if (orderId.isEmpty || riderId.isEmpty) return;

    final orderSnap = await _db.collection(FirestoreConstants.orders).doc(orderId).get();
    if (!orderSnap.exists) return;
    
    final orderData = orderSnap.data()!;
    final subtotal = (orderData[FirestoreConstants.subtotal] as num? ?? 0).toDouble();
    final commission = (orderData[FirestoreConstants.commissionAmount] as num? ?? 0).toDouble();
    final deliveryFee = (orderData[FirestoreConstants.deliveryFee] as num? ?? 0).toDouble();
    final restaurantId = orderData[FirestoreConstants.restaurantId] as String?;
    final restaurantName = orderData[FirestoreConstants.restaurantName] as String? ?? 'Restaurant';

    final batch = _db.batch();

    // 1. Update Order Status
    final orderRef = _db.collection(FirestoreConstants.orders).doc(orderId);
    batch.update(orderRef, {
      FirestoreConstants.status: FirestoreConstants.statusDelivered,
      FirestoreConstants.deliveredAt: FieldValue.serverTimestamp(),
    });

    // 2. Update Rider Availability
    final riderRef = _db.collection(FirestoreConstants.users).doc(riderId);
    batch.update(riderRef, {
      FirestoreConstants.status: FirestoreConstants.riderStatusAvailable,
      FirestoreConstants.activeOrderId: FieldValue.delete(),
    });

    // 3. Process Financials: Rider Earnings
    final riderWalletRef = _db.collection(FirestoreConstants.wallets).doc(riderId);
    batch.set(riderWalletRef, {
      'balance': FieldValue.increment(deliveryFee),
      'totalEarned': FieldValue.increment(deliveryFee),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final riderTxnRef = riderWalletRef.collection(FirestoreConstants.walletTransactions).doc();
    batch.set(riderTxnRef, {
      'amount': deliveryFee,
      'type': 'earnings',
      'description': 'Delivery fee for order #$orderId',
      'orderId': orderId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 4. Process Financials: Restaurant Earnings
    if (restaurantId != null) {
      final restaurantWalletRef = _db.collection(FirestoreConstants.wallets).doc(restaurantId);
      final restaurantEarnings = subtotal - commission;

      batch.set(restaurantWalletRef, {
        'balance': FieldValue.increment(restaurantEarnings),
        'totalEarned': FieldValue.increment(restaurantEarnings),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final restaurantTxnRef = restaurantWalletRef.collection(FirestoreConstants.walletTransactions).doc();
      batch.set(restaurantTxnRef, {
        'amount': restaurantEarnings,
        'type': 'earnings',
        'description': 'Earnings from order #$orderId',
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 5. Notify Customer
    final userId = orderData[FirestoreConstants.userId];
    if (userId != null) {
      await _db.collection(FirestoreConstants.notifications).add({
        FirestoreConstants.userId: userId,
        FirestoreConstants.title: 'Order Delivered',
        FirestoreConstants.body: 'Your order from $restaurantName has been delivered. Enjoy!',
        FirestoreConstants.type: 'order_delivered',
        'orderId': orderId,
        FirestoreConstants.isRead: false,
        FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<Map<String, dynamic>?> getWallet(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _db.collection(FirestoreConstants.wallets).doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return {
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalWithdrawn': 0.0,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getWalletTransactions(String id) {
    if (id.isEmpty) return Stream.value([]);
    return _db
        .collection(FirestoreConstants.wallets)
        .doc(id)
        .collection(FirestoreConstants.walletTransactions)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  FirestoreConstants.id: doc.id,
                })
            .toList());
  }

  Future<void> requestWithdrawal(String id, double amount, String method, String details) async {
    if (id.isEmpty || amount <= 0) return;

    final walletRef = _db.collection(FirestoreConstants.wallets).doc(id);
    final walletSnap = await walletRef.get();
    final balance = (walletSnap.data()?['balance'] as num? ?? 0).toDouble();

    if (balance < amount) throw Exception("Insufficient balance");

    final batch = _db.batch();

    // 1. Deduct from balance
    batch.update(walletRef, {
      'balance': FieldValue.increment(-amount),
      'totalWithdrawn': FieldValue.increment(amount),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 2. Record Transaction
    final txnRef = walletRef.collection(FirestoreConstants.walletTransactions).doc();
    batch.set(txnRef, {
      'amount': -amount,
      'type': 'withdrawal',
      'description': 'Withdrawal request via $method',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Create global withdrawal request for Super Admin
    final requestRef = _db.collection('withdrawal_requests').doc();
    batch.set(requestRef, {
      'userId': id,
      'amount': amount,
      'method': method,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<Map<String, dynamic>> getAppConfig() {
    return _db
        .collection(FirestoreConstants.appConfig)
        .doc('settings')
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {});
  }

  Future<void> updateAppConfig(Map<String, dynamic> config) async {
    await _db
        .collection(FirestoreConstants.appConfig)
        .doc('settings')
        .set(config, SetOptions(merge: true));
  }

  Future<void> acceptOrder(String orderId, String riderId, String riderName) async {
    if (orderId.isEmpty || riderId.isEmpty) return;
    final batch = _db.batch();

    // Get rider's phone first
    final riderDoc = await _db.collection(FirestoreConstants.users).doc(riderId).get();
    final riderPhone = riderDoc.data()?[FirestoreConstants.phone] ?? riderDoc.data()?[FirestoreConstants.phoneNumber] ?? '';

    // 1. Update Order
    final orderRef = _db.collection(FirestoreConstants.orders).doc(orderId);
    batch.update(orderRef, {
      FirestoreConstants.riderId: riderId,
      FirestoreConstants.riderName: riderName,
      'riderPhone': riderPhone,
      FirestoreConstants.status: FirestoreConstants.statusOnTheWay,
      FirestoreConstants.onTheWayAt: FieldValue.serverTimestamp(),
    });

    // 2. Update Rider Status
    final riderRef = _db.collection(FirestoreConstants.users).doc(riderId);
    batch.update(riderRef, {
      FirestoreConstants.status: FirestoreConstants.riderStatusBusy,
      FirestoreConstants.activeOrderId: orderId,
    });

    await batch.commit();
  }

  Stream<Map<String, dynamic>?> getRiderById(String riderId) {
    if (riderId.isEmpty) return Stream.value(null);
    return _db.collection(FirestoreConstants.users).doc(riderId).snapshots().map((doc) {
      final data = doc.data();
      if (doc.exists && data != null) {
        return {
          FirestoreConstants.id: doc.id,
          ...data
        };
      }
      return null;
    });
  }

  Future<void> updateRiderLocation(String riderId, double lat, double lng) async {
    if (riderId.isEmpty) return;
    await _db.collection(FirestoreConstants.users).doc(riderId).update({
      FirestoreConstants.currentLocation: GeoPoint(lat, lng),
    });
  }

  Stream<List<Map<String, dynamic>>> getAvailableRiders({String? adminId}) {
    Query query = _db
        .collection(FirestoreConstants.users)
        .where(FirestoreConstants.role, isEqualTo: FirestoreConstants.roleRider)
        .where(FirestoreConstants.status, isEqualTo: FirestoreConstants.riderStatusAvailable);

    if (adminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                FirestoreConstants.id: doc.id,
                ...doc.data() as Map<String, dynamic>
              })
          .toList();
    });
  }

  Future<void> assignRiderToOrder(String orderId, String riderId, String riderName) async {
    if (orderId.isEmpty || riderId.isEmpty) return;
    final batch = _db.batch();

    // 1. Update Order
    final orderRef = _db.collection(FirestoreConstants.orders).doc(orderId);
    batch.update(orderRef, {
      FirestoreConstants.riderId: riderId,
      FirestoreConstants.riderName: riderName,
      FirestoreConstants.status: FirestoreConstants.statusPreparing, // Or On the way? Usually Preparing -> Assign -> On the way
    });

    // 2. Update Rider Status
    final riderRef = _db.collection(FirestoreConstants.users).doc(riderId);
    batch.update(riderRef, {
      FirestoreConstants.status: FirestoreConstants.riderStatusBusy,
      FirestoreConstants.activeOrderId: orderId,
    });

    await batch.commit();

    // 3. Notify Rider
    await _db.collection(FirestoreConstants.notifications).add({
      FirestoreConstants.userId: riderId,
      FirestoreConstants.title: 'New Assignment',
      FirestoreConstants.body: 'You have been assigned a new order #$orderId',
      FirestoreConstants.type: 'order_assigned',
      'orderId': orderId,
      FirestoreConstants.isRead: false,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getRiders({String? adminId}) {
    Query query = _db
        .collection(FirestoreConstants.users)
        .where(FirestoreConstants.role, isEqualTo: FirestoreConstants.roleRider);

    // If we want riders to be multi-tenant as well
    if (adminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                FirestoreConstants.id: doc.id,
                ...doc.data() as Map<String, dynamic>
              })
          .toList();
    });
  }

  Future<void> addRider(Map<String, dynamic> riderData) async {
    await _db.collection(FirestoreConstants.users).add({
      ...riderData,
      FirestoreConstants.role: FirestoreConstants.roleRider,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRider(String riderId, Map<String, dynamic> riderData) async {
    if (riderId.isEmpty) return;
    await _db.collection(FirestoreConstants.users).doc(riderId).update(riderData);
  }

  Future<void> deleteRider(String riderId) async {
    if (riderId.isEmpty) return;
    await _db.collection(FirestoreConstants.users).doc(riderId).delete();
  }

  Stream<List<Map<String, dynamic>>> getPromotions({String? adminId}) {
    Query query = _db.collection(FirestoreConstants.promotions);

    if (adminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                FirestoreConstants.id: doc.id,
                ...doc.data() as Map<String, dynamic>
              })
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getPromotionPerformance({String? adminId}) {
    return getPromotions(adminId: adminId).asyncMap((promos) async {
      List<Map<String, dynamic>> performanceData = [];
      
      for (var promo in promos) {
        final code = promo[FirestoreConstants.code] as String?;
        if (code == null) continue;

        // In a real app, we would query orders that used this promo code.
        // For now, we fetch stats if they exist in the promo doc, or provide defaults.
        performanceData.add({
          ...promo,
          FirestoreConstants.redemptions: promo[FirestoreConstants.redemptions] ?? 0,
          FirestoreConstants.revenueGenerated: promo[FirestoreConstants.revenueGenerated] ?? 0.0,
          FirestoreConstants.newCustomers: promo[FirestoreConstants.newCustomers] ?? 0,
          FirestoreConstants.roi: promo[FirestoreConstants.roi] ?? '0.0x',
        });
      }
      return performanceData;
    });
  }

  Future<void> addPromotion(Map<String, dynamic> promoData) async {
    final String? currentAdminId = _auth.currentUser?.uid;
    await _db.collection(FirestoreConstants.promotions).add({
      ...promoData,
      FirestoreConstants.adminId: currentAdminId,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePromotion(String promoId, Map<String, dynamic> promoData) async {
    if (promoId.isEmpty) return;
    await _db.collection(FirestoreConstants.promotions).doc(promoId).update(promoData);
  }

  Future<void> deletePromotion(String promoId) async {
    if (promoId.isEmpty) return;
    await _db.collection(FirestoreConstants.promotions).doc(promoId).delete();
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection(FirestoreConstants.notifications)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .orderBy(FirestoreConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        FirestoreConstants.id: doc.id,
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getAdminNotifications({String? adminId, String? restaurantId}) {
    Query query = _db.collection(FirestoreConstants.notifications);

    if (adminId != null && adminId.isNotEmpty) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }
    
    if (restaurantId != null && restaurantId.isNotEmpty) {
      query = query.where(FirestoreConstants.restaurantId, isEqualTo: restaurantId);
    }

    return query
        .orderBy(FirestoreConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => <String, dynamic>{
        ...doc.data() as Map<String, dynamic>,
        FirestoreConstants.id: doc.id,
      }).toList();
    });
  }

  Future<void> addAdminNotification(Map<String, dynamic> notificationData) async {
    final String? currentAdminId = _auth.currentUser?.uid;
    await _db.collection(FirestoreConstants.notifications).add({
      ...notificationData,
      FirestoreConstants.adminId: currentAdminId,
      FirestoreConstants.isRead: false,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAdminNotification(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _db.collection(FirestoreConstants.notifications).doc(notificationId).delete();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _db.collection(FirestoreConstants.notifications).doc(notificationId).update({
      FirestoreConstants.isRead: true,
    });
  }

  Future<void> updateNotificationPreferences(String userId, {bool? push, bool? sms, bool? email}) async {
    if (userId.isEmpty) return;
    final Map<String, dynamic> updates = {};
    if (push != null) updates[FirestoreConstants.pushEnabled] = push;
    if (sms != null) updates[FirestoreConstants.smsEnabled] = sms;
    if (email != null) updates[FirestoreConstants.emailEnabled] = email;
    
    if (updates.isNotEmpty) {
      await _db.collection(FirestoreConstants.users).doc(userId).update(updates);
    }
  }

  Future<void> markAllNotificationsAsRead(String userId, {bool isAdmin = false}) async {
    final query = isAdmin
        ? _db.collection(FirestoreConstants.notifications).where(FirestoreConstants.adminId, isEqualTo: userId)
        : _db.collection(FirestoreConstants.notifications).where(FirestoreConstants.userId, isEqualTo: userId);

    final snapshot = await query.where(FirestoreConstants.isRead, isEqualTo: false).get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {FirestoreConstants.isRead: true});
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCommissionData(String? adminId, DateTime startOfMonth, DateTime endOfMonth) async {
    // Load only restaurants belonging to this admin
    Query restaurantsQuery = _db.collection(FirestoreConstants.restaurants);
    if (adminId != null) {
      restaurantsQuery = restaurantsQuery.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }
    final restaurantsSnap = await restaurantsQuery.get();

    // Load orders for this admin
    Query ordersQuery = _db
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.createdAt, isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where(FirestoreConstants.createdAt, isLessThan: Timestamp.fromDate(endOfMonth))
        .where(FirestoreConstants.status, isEqualTo: FirestoreConstants.statusDelivered);

    if (adminId != null) {
      ordersQuery = ordersQuery.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }

    final ordersSnap = await ordersQuery.get();

    final Map<String, List<Map<String, dynamic>>> ordersByRestaurant = {};
    for (var doc in ordersSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final restaurantId = data[FirestoreConstants.restaurantId] ?? '';
      if (restaurantId.isEmpty) continue;
      ordersByRestaurant.putIfAbsent(restaurantId, () => []);
      ordersByRestaurant[restaurantId]!.add(data);
    }

    final List<Map<String, dynamic>> list = [];
    for (var restaurantDoc in restaurantsSnap.docs) {
      final rData = restaurantDoc.data() as Map<String, dynamic>;
      final rId = restaurantDoc.id;
      final rOrders = ordersByRestaurant[rId] ?? [];

      final double rRate = (rData[FirestoreConstants.commissionRate] ?? 15).toDouble();

      double revenue = 0;
      double commission = 0;
      for (var o in rOrders) {
        revenue += (o[FirestoreConstants.totalAmount] ?? 0).toDouble();
        // Use the commission stored in the order, or calculate from current rate if missing
        if (o.containsKey(FirestoreConstants.commissionAmount)) {
          commission += (o[FirestoreConstants.commissionAmount] ?? 0).toDouble();
        } else {
          final double orderRate = (o[FirestoreConstants.commissionRate] ?? rRate).toDouble();
          commission += (o[FirestoreConstants.totalAmount] ?? 0).toDouble() * (orderRate / 100);
        }
      }

      final paymentDoc = await _db
          .collection(FirestoreConstants.commissions)
          .doc('${rId}_${startOfMonth.year}_${startOfMonth.month}')
          .get();

      final paymentDocData = paymentDoc.data();
      final isPaid = paymentDoc.exists && (paymentDocData?[FirestoreConstants.isPaid] == true);

      list.add({
        FirestoreConstants.restaurantId: rId,
        FirestoreConstants.restaurantName: rData[FirestoreConstants.name] ?? 'Unknown',
        FirestoreConstants.totalOrders: rOrders.length,
        FirestoreConstants.totalRevenue: revenue,
        FirestoreConstants.commissionRate: rRate,
        FirestoreConstants.commissionAmount: commission,
        FirestoreConstants.isPaid: isPaid,
        FirestoreConstants.month: startOfMonth,
      });
    }
    return list;
  }

  Future<void> markCommissionAsPaid(String docId, Map<String, dynamic> data) async {
    final String? adminId = _auth.currentUser?.uid;
    await _db.collection(FirestoreConstants.commissions).doc(docId).set({
      ...data,
      ...?adminId != null ? {FirestoreConstants.adminId: adminId} : null,
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getCommissionHistory({String? adminId}) {
    Query query = _db.collection(FirestoreConstants.commissions);
    
    if (adminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }

    return query
        .orderBy(FirestoreConstants.year, descending: true)
        .orderBy(FirestoreConstants.month, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  Future<void> addRestaurant(Map<String, dynamic> restaurantData) async {
    final String? currentAdminId = _auth.currentUser?.uid;
    await _db.collection(FirestoreConstants.restaurants).add({
      ...restaurantData,
      FirestoreConstants.adminId: currentAdminId,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> restaurantData) async {
    if (restaurantId.isEmpty) return;
    await _db.collection(FirestoreConstants.restaurants).doc(restaurantId).update(restaurantData);
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    if (restaurantId.isEmpty) return;
    
    // 1. Delete all menu items under this restaurant
    final menuSnapshot = await _db
        .collection(FirestoreConstants.restaurants)
        .doc(restaurantId)
        .collection(FirestoreConstants.menu)
        .get();
        
    final batch = _db.batch();
    for (var doc in menuSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // 2. Delete the restaurant document
    batch.delete(_db.collection(FirestoreConstants.restaurants).doc(restaurantId));
    
    await batch.commit();
  }

  Future<Map<String, dynamic>?> validatePromoCode(String code) async {
    try {
      final query = await _db
          .collection(FirestoreConstants.promotions)
          .where(FirestoreConstants.code, isEqualTo: code.toUpperCase().trim())
          .where(FirestoreConstants.status, isEqualTo: 'Active')
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final promo = query.docs.first.data();
      promo[FirestoreConstants.id] = query.docs.first.id;
      return promo;
    } catch (e) {
      debugPrint("Error validating promo code: $e");
      return null;
    }
  }

  Future<void> incrementPromoRedemption(String promoId) async {
    if (promoId.isEmpty) return;
    try {
      await _db
          .collection(FirestoreConstants.promotions)
          .doc(promoId)
          .update({
        FirestoreConstants.redemptions: FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error incrementing promo redemption: $e");
    }
  }

  Future<void> addMenuItem(String restaurantId, Map<String, dynamic> itemData) async {
    if (restaurantId.isEmpty) return;
    final docRef = await _db
        .collection(FirestoreConstants.restaurants)
        .doc(restaurantId)
        .collection(FirestoreConstants.menu)
        .add({
      ...itemData,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    });
    
    await _audit.logMenuUpdate(restaurantId, docRef.id, 'ADD_MENU_ITEM');
  }

  Future<void> updateMenuItem(String restaurantId, String itemId, Map<String, dynamic> itemData) async {
    if (restaurantId.isEmpty || itemId.isEmpty) return;
    await _db
        .collection(FirestoreConstants.restaurants)
        .doc(restaurantId)
        .collection(FirestoreConstants.menu)
        .doc(itemId)
        .update(itemData);

    await _audit.logMenuUpdate(restaurantId, itemId, 'UPDATE_MENU_ITEM');
  }

  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    if (restaurantId.isEmpty || itemId.isEmpty) return;
    await _db
        .collection(FirestoreConstants.restaurants)
        .doc(restaurantId)
        .collection(FirestoreConstants.menu)
        .doc(itemId)
        .delete();

    await _audit.logMenuUpdate(restaurantId, itemId, 'DELETE_MENU_ITEM');
  }

  Stream<Map<String, dynamic>?> getRestaurantByIdStream(String id) {
    if (id.isEmpty) {
      debugPrint('❌ Error: getRestaurantByIdStream called with empty ID');
      return Stream.value(null);
    }
    return _db.collection(FirestoreConstants.restaurants).doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (doc.exists && data != null) {
        return <String, dynamic>{
          FirestoreConstants.id: doc.id,
          ...data
        };
      }
      return null;
    });
  }

  Stream<List<MessageModel>> getMessages(String orderId) {
    return _db
        .collection(FirestoreConstants.orders)
        .doc(orderId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendMessage(String orderId, MessageModel message) async {
    if (orderId.isEmpty) return;
    await _db
        .collection(FirestoreConstants.orders)
        .doc(orderId)
        .collection('chat')
        .add(message.toMap());
  }

  Future<void> toggleFavorite(String userId, String pizzaId) async {
    if (userId.isEmpty || pizzaId.isEmpty) return;
    final favRef = _db.collection(FirestoreConstants.users).doc(userId).collection('favorites').doc(pizzaId);
    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'pizzaId': pizzaId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isFavorite(String userId, String pizzaId) {
    if (userId.isEmpty || pizzaId.isEmpty) return Stream.value(false);
    return _db
        .collection(FirestoreConstants.users)
        .doc(userId)
        .collection('favorites')
        .doc(pizzaId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<Map<String, dynamic>?> getRestaurantById(String id) async {
    if (id.isEmpty) return null;
    try {
      final doc = await _db.collection(FirestoreConstants.restaurants).doc(id).get();
      final data = doc.data();
      if (doc.exists && data != null) {
        return <String, dynamic>{
          ...data,
          FirestoreConstants.id: doc.id,
        };
      }
    } catch (e) {
      debugPrint("Error getting restaurant by id: $e");
    }
    return null;
  }

  Future<void> initializeDemoData({required String adminId, bool forceRefresh = false}) async {
    final restaurantsRef = _db.collection(FirestoreConstants.restaurants);
    final dealsRef = _db.collection(FirestoreConstants.deals);
    
    // Only fetch/refresh data belonging to this admin
    final adminRestaurants = await restaurantsRef.where(FirestoreConstants.adminId, isEqualTo: adminId).get();

    if (forceRefresh) {
      for (var doc in adminRestaurants.docs) {
        final menuSnapshot = await doc.reference.collection(FirestoreConstants.menu).get();
        for (var menuDoc in menuSnapshot.docs) {
          await menuDoc.reference.delete();
        }
        await doc.reference.delete();
      }
      
      final dealsSnapshot = await dealsRef.where(FirestoreConstants.adminId, isEqualTo: adminId).get();
      for (var doc in dealsSnapshot.docs) {
        await doc.reference.delete();
      }
    }

    if (!forceRefresh && adminRestaurants.docs.isNotEmpty) return;

    // 1. Initialize Restaurants with adminId
    Map<String, String> restaurantIds = {};
    
    final List<Map<String, dynamic>> restaurants = [
      <String, dynamic>{
        FirestoreConstants.adminId: adminId,
        FirestoreConstants.name: 'Cookoz',
        FirestoreConstants.description: 'The best stuffed crust & zingers in Vehari',
        FirestoreConstants.rating: '4.5',
        FirestoreConstants.time: '20-30 min',
        FirestoreConstants.delivery: 'Free Delivery',
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        FirestoreConstants.address: 'Club Road, Vehari',
        FirestoreConstants.menu: <Map<String, dynamic>>[
          <String, dynamic>{
            FirestoreConstants.name: 'Pepperoni Feast (S)',
            FirestoreConstants.price: 600,
            FirestoreConstants.description: 'Small size pepperoni and mozzarella',
            FirestoreConstants.image: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400',
            FirestoreConstants.category: 'Medium Pizzas',
            FirestoreConstants.isBestSeller: true,
            FirestoreConstants.rating: 4.8,
          },
        ]
      },
      // ... adding other restaurants similarly tagged with adminId
    ];

    for (var restaurant in restaurants) {
      final menu = (restaurant.remove(FirestoreConstants.menu) as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final docRef = await restaurantsRef.add(restaurant);
      restaurantIds[restaurant[FirestoreConstants.name] as String] = docRef.id;
      if (menu != null) {
        for (var item in menu) {
          item[FirestoreConstants.adminId] = adminId;
          await docRef.collection(FirestoreConstants.menu).add(item);
        }
      }
    }

    // 2. Initialize Deals with adminId
    final deals = [
      {
        FirestoreConstants.adminId: adminId,
        FirestoreConstants.title: 'Mega Deal Box',
        FirestoreConstants.description: '2 Large Pizzas + 2 Drinks',
        FirestoreConstants.imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
        FirestoreConstants.originalPrice: 2400,
        FirestoreConstants.discountedPrice: 1499,
        FirestoreConstants.discountPercent: 38,
        FirestoreConstants.tag: 'HOT',
        FirestoreConstants.expiresAt: Timestamp.fromDate(DateTime.now().add(const Duration(hours: 5))),
        FirestoreConstants.restaurantId: restaurantIds['Cookoz'] ?? '',
        FirestoreConstants.restaurantName: 'Cookoz',
        FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
      },
    ];

    for (var deal in deals) {
      await dealsRef.add(deal);
    }
  }

  Future<void> placeOrders({
    required String userId,
    required List<CartGroup> cartGroups,
    required String address,
    required String userPhone, // Added for validation
    required String userName,  // Added for validation
    double? lat,
    double? lng,
    required String paymentMethod,
    String? promoCode,
  }) async {
    try {
      if (userId.isEmpty) throw Exception("User ID is empty");

      // ── Step 1: Client side validation ───────────────────────────────────
      final phoneRegex = RegExp(r'^03\d{9}$');
      if (!phoneRegex.hasMatch(userPhone)) throw Exception("Invalid phone format");

      final nameRegex = RegExp(r'^[a-zA-Z\s]{3,30}$');
      if (!nameRegex.hasMatch(userName)) throw Exception("Invalid name format");

      // ── Step 2: Create Order Requests (Drafts) ──────────────────────────
      // This collection has rules that prevent setting the 'totalAmount'.
      // A Cloud Function should watch this collection, verify prices, and 
      // create the final Order document.
      
      final String checkoutId = _db.collection('checkouts').doc().id;
      final batch = _db.batch();
      final String deliveryPin = (1000 + Random().nextInt(9000)).toString();

      for (var group in cartGroups) {
        final requestRef = _db.collection('order_requests').doc();
        
        final requestData = {
          'userId': userId,
          'userName': userName,
          'userPhone': userPhone,
          'parentCheckoutId': checkoutId,
          'restaurantId': group.restaurantId,
          'restaurantName': group.restaurantName,
          'items': group.items.map((item) => {
            'pizzaId': item.pizza.id,
            'quantity': item.quantity,
            'size': item.size,
            'extraToppings': item.extraToppings,
            'instructions': item.instructions,
          }).toList(),
          'address': address,
          'lat': lat,
          'lng': lng,
          'paymentMethod': paymentMethod,
          'promoCode': promoCode,
          'deliveryPin': deliveryPin,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Draft',
        };

        batch.set(requestRef, requestData);
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Security Violation / Error: $e");
      rethrow;
    }
  }

  @Deprecated('Use placeOrders instead for multi-restaurant support')
  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double totalAmount,
    double? discountAmount,
    String? promoCode,
    required String address,
    double? lat,
    double? lng,
    required String paymentMethod,
    String? restaurantId,
    String? restaurantName,
  }) async {
    try {
      if (userId.isEmpty) throw Exception("User ID is empty");

      final userDoc = await _db.collection(FirestoreConstants.users).doc(userId).get();
      final userDocData = userDoc.data();
      final userName = userDocData?[FirestoreConstants.name] ?? 'User';

      String? targetAdminId;
      double commissionRate = 15.0;
      if (restaurantId != null) {
        final resDoc = await _db.collection(FirestoreConstants.restaurants).doc(restaurantId).get();
        final resData = resDoc.data();
        targetAdminId = resData != null ? resData[FirestoreConstants.adminId] as String? : null;
        commissionRate = (resData?[FirestoreConstants.commissionRate] ?? 15.0).toDouble();
      }

      double commissionAmount = totalAmount * (commissionRate / 100);

      DocumentReference orderRef = await _db.collection(FirestoreConstants.orders).add({
        FirestoreConstants.userId: userId,
        FirestoreConstants.adminId: targetAdminId,
        FirestoreConstants.userName: userName,
        FirestoreConstants.restaurantId: restaurantId,
        FirestoreConstants.restaurantName: restaurantName,
        FirestoreConstants.items: items,
        FirestoreConstants.subtotal: subtotal,
        FirestoreConstants.deliveryFee: deliveryFee,
        FirestoreConstants.tax: tax,
        FirestoreConstants.totalAmount: totalAmount,
        FirestoreConstants.discountAmount: discountAmount,
        FirestoreConstants.promoCode: promoCode,
        FirestoreConstants.commissionRate: commissionRate,
        FirestoreConstants.commissionAmount: commissionAmount,
        FirestoreConstants.address: address,
        'deliveryLat': lat,
        'deliveryLng': lng,
        FirestoreConstants.paymentMethod: paymentMethod,
        FirestoreConstants.status: FirestoreConstants.statusPending,
        FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
      });

      await _db.collection(FirestoreConstants.users).doc(userId).set({
        FirestoreConstants.userOrdersCount: FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Send notification for new order (Mocking the server-side logic here)
      await addAdminNotification({
        FirestoreConstants.adminId: targetAdminId,
        FirestoreConstants.title: 'New Order Received',
        FirestoreConstants.body: 'A new order has been placed for $restaurantName. Total: Rs $totalAmount',
        FirestoreConstants.type: 'new_order',
        'orderId': orderRef.id,
      });

      return orderRef.id;
    } catch (e) {
      debugPrint("Error placing order: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getOrders(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => <String, dynamic>{
                ...doc.data(),
                FirestoreConstants.id: doc.id,
              })
          .toList();
      orders.sort((a, b) {
        final aTime = (a[FirestoreConstants.createdAt] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (b[FirestoreConstants.createdAt] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      return orders;
    });
  }

  Stream<List<Map<String, dynamic>>> getCustomers({String? adminId}) {
    // If adminId is provided, we might want to filter customers who have ordered from this admin's restaurants.
    // However, customers are in a global collection. A better approach for multi-tenancy is to filter them in the UI
    // based on their interaction with the admin's orders, or just list all customers if that's the intended admin capability.
    // Given the project scope, we'll return all customers but the caller can filter.
    return _db
        .collection(FirestoreConstants.users)
        .where(FirestoreConstants.role, isEqualTo: FirestoreConstants.roleCustomer)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  FirestoreConstants.id: doc.id,
                  ...doc.data()
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getAllOrders({String? adminId, String? restaurantId}) {
    Query query = _db.collection(FirestoreConstants.orders);

    if (adminId != null && adminId.isNotEmpty) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }
    
    if (restaurantId != null && restaurantId.isNotEmpty) {
      query = query.where(FirestoreConstants.restaurantId, isEqualTo: restaurantId);
    }

    return query.orderBy(FirestoreConstants.createdAt, descending: true).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => <String, dynamic>{
              ...doc.data() as Map<String, dynamic>,
              FirestoreConstants.id: doc.id,
            })
        .toList());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final orderDoc = await _db.collection(FirestoreConstants.orders).doc(orderId).get();
      final orderData = orderDoc.data();
      final userId = orderData?[FirestoreConstants.userId];
      final restaurantName = orderData?[FirestoreConstants.restaurantName];

      final Map<String, dynamic> updates = {FirestoreConstants.status: status};
      
      String notificationTitle = 'Order Status Updated';
      String notificationBody = 'Your order from $restaurantName is now: $status';

      if (status == FirestoreConstants.statusPreparing) {
        updates[FirestoreConstants.preparingAt] = FieldValue.serverTimestamp();
        notificationTitle = 'Order Preparing';
        notificationBody = 'The kitchen has started preparing your delicious pizza!';
      } else if (status == FirestoreConstants.statusOnTheWay) {
        updates[FirestoreConstants.onTheWayAt] = FieldValue.serverTimestamp();
        notificationTitle = 'Order on the Way';
        notificationBody = 'Your rider is heading to your location. Get ready!';
      } else if (status == FirestoreConstants.statusDelivered) {
        updates[FirestoreConstants.deliveredAt] = FieldValue.serverTimestamp();
        notificationTitle = 'Order Delivered';
        notificationBody = 'Enjoy your meal! Don\'t forget to rate us.';
      } else if (status == FirestoreConstants.statusCancelled) {
        updates[FirestoreConstants.cancelledAt] = FieldValue.serverTimestamp();
        notificationTitle = 'Order Cancelled';
        notificationBody = 'Your order from $restaurantName has been cancelled.';
      }

      await _db.collection(FirestoreConstants.orders).doc(orderId).update(updates);

      // Log the status update
      await _audit.logOrderUpdate(orderId, status);

      // Notify customer about status change
      if (userId != null) {
        await _db.collection(FirestoreConstants.notifications).add({
          FirestoreConstants.userId: userId,
          FirestoreConstants.title: notificationTitle,
          FirestoreConstants.body: notificationBody,
          FirestoreConstants.type: 'order_status',
          'orderId': orderId,
          FirestoreConstants.isRead: false,
          FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error updating order status: $e");
      rethrow;
    }
  }

  Future<void> submitOrderRating({
    required String orderId,
    required String restaurantId,
    required String? riderId,
    required double foodRating,
    required double riderRating,
    required String review,
  }) async {
    final batch = _db.batch();

    // 1. Save rating on the order itself
    final orderRef = _db.collection(FirestoreConstants.orders).doc(orderId);
    batch.update(orderRef, {
      FirestoreConstants.foodRating: foodRating,
      FirestoreConstants.riderRating: riderRating,
      FirestoreConstants.review: review,
      FirestoreConstants.ratingSubmitted: true,
      FirestoreConstants.ratedAt: FieldValue.serverTimestamp(),
    });

    // 2. Update restaurant's average rating
    final restaurantRef = _db.collection(FirestoreConstants.restaurants).doc(restaurantId);
    batch.update(restaurantRef, {
      FirestoreConstants.totalRatingSum: FieldValue.increment(foodRating),
      FirestoreConstants.totalRatingCount: FieldValue.increment(1),
    });

    // 3. Update rider's average rating (if assigned)
    if (riderId != null) {
      final riderRef = _db.collection(FirestoreConstants.users).doc(riderId);
      batch.update(riderRef, {
        FirestoreConstants.totalRatingSum: FieldValue.increment(riderRating),
        FirestoreConstants.totalRatingCount: FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getOrdersByCheckoutId(String checkoutId) {
    return _db
        .collection(FirestoreConstants.orders)
        .where('parentCheckoutId', isEqualTo: checkoutId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  FirestoreConstants.id: doc.id,
                })
            .toList());
  }

  Stream<Map<String, dynamic>?> getOrderById(String orderId) {
    if (orderId.isEmpty) {
      debugPrint('❌ Error: getOrderById called with empty orderId');
      return Stream.value(null);
    }
    return _db.collection(FirestoreConstants.orders).doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      if (doc.exists && data != null) {
        return <String, dynamic>{
          ...data,
          FirestoreConstants.id: doc.id,
        };
      }
      return null;
    });
  }

  Future<bool> cancelOrder(String orderId) async {
    if (orderId.isEmpty) return false;
    try {
      final docRef = _db.collection(FirestoreConstants.orders).doc(orderId);
      final doc = await docRef.get();
      final data = doc.data();

      if (doc.exists && data?[FirestoreConstants.status] == FirestoreConstants.statusPending) {
        await docRef.update({
          FirestoreConstants.status: FirestoreConstants.statusCancelled,
          FirestoreConstants.cancelledAt: FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error cancelling order: $e");
      return false;
    }
  }

  Future<void> saveAddress(String userId, Map<String, dynamic> addressData) async {
    if (userId.isEmpty) return;
    try {
      await _db
          .collection(FirestoreConstants.users)
          .doc(userId)
          .collection(FirestoreConstants.addresses)
          .add({
        ...addressData,
        FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving address: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAddresses(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection(FirestoreConstants.users)
        .doc(userId)
        .collection(FirestoreConstants.addresses)
        .orderBy(FirestoreConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  FirestoreConstants.id: doc.id,
                })
            .toList());
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) return;
    try {
      await _db
          .collection(FirestoreConstants.users)
          .doc(userId)
          .collection(FirestoreConstants.addresses)
          .doc(addressId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting address: $e");
      rethrow;
    }
  }

  Future<void> updateAddress(String userId, String addressId, Map<String, dynamic> addressData) async {
    if (userId.isEmpty || addressId.isEmpty) return;
    try {
      await _db
          .collection(FirestoreConstants.users)
          .doc(userId)
          .collection(FirestoreConstants.addresses)
          .doc(addressId)
          .update(addressData);
    } catch (e) {
      debugPrint("Error updating address: $e");
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (userId.isEmpty || addressId.isEmpty) return;
    try {
      final batch = _db.batch();
      final addressesRef = _db.collection(FirestoreConstants.users).doc(userId).collection(FirestoreConstants.addresses);
      final snapshot = await addressesRef.get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {FirestoreConstants.isDefault: doc.id == addressId});
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Error setting default address: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDefaultAddress(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final snapshot = await _db
          .collection(FirestoreConstants.users)
          .doc(userId)
          .collection(FirestoreConstants.addresses)
          .where(FirestoreConstants.isDefault, isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return <String, dynamic>{
          ...data,
          FirestoreConstants.id: snapshot.docs.first.id,
        };
      }
      return null;
    } catch (e) {
      debugPrint("Error getting default address: $e");
      return null;
    }
  }

  Future<void> addPizzaOClockMenu({String? restaurantId, String? restaurantName}) async {
    final String? adminId = _auth.currentUser?.uid;
    if (adminId == null) throw Exception("User not authenticated");

    String targetId = restaurantId ?? '';
    String targetName = restaurantName ?? 'Pizza O Clock';

    if (targetId.isEmpty) {
      final existing = await _db
          .collection(FirestoreConstants.restaurants)
          .where(FirestoreConstants.adminId, isEqualTo: adminId)
          .where(FirestoreConstants.name, isEqualTo: 'Pizza O Clock')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        targetId = existing.docs.first.id;
      } else {
        final newRes = await _db.collection(FirestoreConstants.restaurants).add({
          FirestoreConstants.adminId: adminId,
          FirestoreConstants.name: 'Pizza O Clock',
          FirestoreConstants.description: 'Authentic Italian & Special Square Pizzas',
          FirestoreConstants.rating: '4.8',
          FirestoreConstants.time: '30-45 min',
          FirestoreConstants.delivery: 'Free Delivery',
          FirestoreConstants.image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
          FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
          FirestoreConstants.commissionRate: 15.0,
        });
        targetId = newRes.id;
      }
    }

    final menuRef = _db
        .collection(FirestoreConstants.restaurants)
        .doc(targetId)
        .collection(FirestoreConstants.menu);

    final List<Map<String, dynamic>> menuItems = [
      // ── APPETIZERS ──────────────────────────────────────────────────
      {
        FirestoreConstants.name: 'Cheesey Sticks',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: '4 pieces of cheese & white sauce stuffed bread sticks served with dip sauce',
        FirestoreConstants.price: 480,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Oven Baked Wings (Honey 12pcs)',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: 'Honey wings (12 pcs)',
        FirestoreConstants.price: 760,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Oven Baked Wings (Spicy 12pcs)',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: 'Spicy & juicy wings (12 pcs)',
        FirestoreConstants.price: 740,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Oven Baked Wings (Honey 6pcs)',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: 'Honey wings (6 pcs)',
        FirestoreConstants.price: 380,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Oven Baked Wings (Spicy 6pcs)',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: 'Spicy & juicy wings (6 pcs)',
        FirestoreConstants.price: 410,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Kabab Sticks',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: '4 pieces of white sauce loaded kebab stuffed bread sticks served with dip sauce',
        FirestoreConstants.price: 500,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Mexican Sandwich',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: 'A bun baked with chicken, veggies & cheese with the twist of mayo mustard sauce',
        FirestoreConstants.price: 670,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Oven Baked Rolls',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: 'Four types of delicious fresh & juicy rolls served with mayo dip sauce',
        FirestoreConstants.price: 610,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      {
        FirestoreConstants.name: 'Platter',
        FirestoreConstants.category: 'Appetizer',
        FirestoreConstants.description: '4 pieces of delicious spring rolls served with juicy 6 oven baked wings & mayo dip sauce',
        FirestoreConstants.price: 910,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },

      // ── P.O CLOCK SPECIAL ───────────────────────────────────────────
      {
        FirestoreConstants.name: 'Zinger Burger',
        FirestoreConstants.category: 'P.O Clock Special',
        FirestoreConstants.description: 'Crispy zinger burger with special sauce',
        FirestoreConstants.price: 550,
        FirestoreConstants.image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        FirestoreConstants.restaurantId: targetId,
        FirestoreConstants.restaurantName: targetName,
        FirestoreConstants.isAvailable: true,
      },
      // ... (rest of the items)
    ];

    // Actually I should just use the loop to override them instead of modifying each one in this long list
    for (var item in menuItems) {
      item[FirestoreConstants.restaurantId] = targetId;
      item[FirestoreConstants.restaurantName] = targetName;
    }

    // Upload in batches of 500 (Firestore limit)
    debugPrint('Starting upload of ${menuItems.length} menu items...');
    
    int batchCount = 0;
    WriteBatch batch = _db.batch();
    
    for (int i = 0; i < menuItems.length; i++) {
      final docRef = menuRef.doc();
      batch.set(docRef, {
        ...menuItems[i],
        FirestoreConstants.adminId: _auth.currentUser?.uid,
        FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
      });
      batchCount++;
      
      // Commit every 500 items
      if (batchCount == 500) {
        await batch.commit();
        batch = _db.batch();
        batchCount = 0;
        debugPrint('Committed batch...');
      }
    }
    
    // Commit remaining
    if (batchCount > 0) {
      await batch.commit();
    }
    
    debugPrint('✅ Successfully uploaded ${menuItems.length} menu items for $targetName!');
  }

  Stream<Map<String, dynamic>> getDashboardStats({String? adminId, String? restaurantId}) {
    Query query = _db.collection(FirestoreConstants.orders);
    
    if (adminId != null) {
      query = query.where(FirestoreConstants.adminId, isEqualTo: adminId);
    }
    
    if (restaurantId != null) {
      query = query.where(FirestoreConstants.restaurantId, isEqualTo: restaurantId);
    }

    return query.snapshots().asyncMap((ordersSnap) async {
      final orders = ordersSnap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      final double totalRevenue = orders.fold(0.0, (acc, o) => acc + (o[FirestoreConstants.totalAmount] ?? 0).toDouble());
      final double totalCommission = orders.fold(0.0, (acc, o) => acc + (o[FirestoreConstants.commissionAmount] ?? 0).toDouble());
      final int totalOrders = orders.length;
      final int pendingOrders = orders.where((o) => o[FirestoreConstants.status] == FirestoreConstants.statusPending).length;

      // Stats from other collections
      // Note: restaurants and riders are usually admin-level stats, not necessarily filtered by restaurantId here
      // but for consistency with the UI, we keep adminId filtering.
      final restaurantsSnap = await _db.collection(FirestoreConstants.restaurants)
          .where(FirestoreConstants.adminId, isEqualTo: adminId).get();
      final ridersSnap = await _db.collection(FirestoreConstants.users)
          .where(FirestoreConstants.role, isEqualTo: FirestoreConstants.roleRider)
          .where(FirestoreConstants.adminId, isEqualTo: adminId).get();
      
      final uniqueCustomers = orders.map((o) => o[FirestoreConstants.userId]).toSet().length;

      return {
        FirestoreConstants.totalOrders: totalOrders,
        FirestoreConstants.totalRevenue: totalRevenue,
        FirestoreConstants.totalCommission: totalCommission,
        FirestoreConstants.pendingOrders: pendingOrders,
        FirestoreConstants.totalRestaurants: restaurantsSnap.docs.length,
        FirestoreConstants.totalRiders: ridersSnap.docs.length,
        FirestoreConstants.totalCustomers: uniqueCustomers,
      };
    });
  }
}
