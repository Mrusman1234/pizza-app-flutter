import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_constants.dart';

class MigrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> runAdminMigration() async {
    final String? currentAdminId = _auth.currentUser?.uid;
    if (currentAdminId == null) return;

    try {
      await Future.wait([
        _migrateCollection(FirestoreConstants.restaurants, currentAdminId),
        _migrateCollection(FirestoreConstants.orders, currentAdminId),
        _migrateCollection(FirestoreConstants.promotions, currentAdminId),
        _migrateCollection(FirestoreConstants.notifications, currentAdminId),
        _migrateCollection(FirestoreConstants.deals, currentAdminId),
      ]);
      
      // Seed initial menu data if needed
      await seedInitialMenuData();
      
      debugPrint('✅ All legacy records migrated to admin: $currentAdminId');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
    }
  }

  Future<void> seedInitialMenuData() async {
    final restaurantSnapshot = await _db.collection(FirestoreConstants.restaurants).get();
    if (restaurantSnapshot.docs.isEmpty) return;

    for (var restaurantDoc in restaurantSnapshot.docs) {
      final menuSnapshot = await restaurantDoc.reference.collection(FirestoreConstants.menu).get();
      if (menuSnapshot.docs.isEmpty) {
        // Seed some sample pizzas if menu is empty
        final samplePizzas = [
          {
            'name': 'Margherita Pizza',
            'description': 'Classic tomato sauce, mozzarella, and fresh basil',
            'price': 899.0,
            'category': 'Classic',
            'imageUrl': 'https://images.unsplash.com/photo-1574071318508-1cdbad80ad50',
            'isAvailable': true,
            'isBestSeller': true,
            'rating': 4.8,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Pepperoni Feast',
            'description': 'Loaded with pepperoni and extra mozzarella',
            'price': 1199.0,
            'category': 'Popular',
            'imageUrl': 'https://images.unsplash.com/photo-1628840042765-356cda07504e',
            'isAvailable': true,
            'isBestSeller': true,
            'rating': 4.9,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Chicken Tikka',
            'description': 'Spicy chicken tikka, onions, and green peppers',
            'price': 1099.0,
            'category': 'Local Favorites',
            'imageUrl': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
            'isAvailable': true,
            'isBestSeller': false,
            'rating': 4.7,
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        final batch = _db.batch();
        for (var pizza in samplePizzas) {
          final newDoc = restaurantDoc.reference.collection(FirestoreConstants.menu).doc();
          batch.set(newDoc, pizza);
        }
        await batch.commit();
        debugPrint('   - Seeded menu for restaurant: ${restaurantDoc.data()['name']}');
      }
    }
  }

  Future<void> _migrateCollection(String collectionPath, String adminId) async {
    final snapshot = await _db.collection(collectionPath).get();
    final batch = _db.batch();
    bool needsCommit = false;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Only migrate if adminId is missing or empty
      if (data['adminId'] == null || data['adminId'].toString().isEmpty) {
        batch.update(doc.reference, {'adminId': adminId});
        needsCommit = true;
      }
    }

    if (needsCommit) {
      await batch.commit();
      debugPrint('   - Migrated ${collectionPath}');
    }
  }
}
