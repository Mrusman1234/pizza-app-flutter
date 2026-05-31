import 'package:flutter/material.dart';
import '../models/commission_model.dart';
import '../services/firestore_service.dart';

class CommissionProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<CommissionModel> _commissions = [];
  bool _isLoading = false;

  List<CommissionModel> get commissions => _commissions;
  bool get isLoading => _isLoading;

  Future<void> fetchCommissions(String? adminId, DateTime month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      
      final data = await _firestoreService.getCommissionData(adminId, startOfMonth, endOfMonth);
      _commissions = data.map((item) => CommissionModel.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error fetching commissions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsPaid(CommissionModel commission) async {
    final docId = '${commission.restaurantId}_${commission.month.year}_${commission.month.month}';
    await _firestoreService.markCommissionAsPaid(docId, {
      ...commission.toMap(),
      'isPaid': true,
    });
    // Refresh local list
    final index = _commissions.indexWhere((c) => c.restaurantId == commission.restaurantId);
    if (index != -1) {
      _commissions[index] = CommissionModel(
        id: commission.id,
        restaurantId: commission.restaurantId,
        restaurantName: commission.restaurantName,
        totalOrders: commission.totalOrders,
        totalRevenue: commission.totalRevenue,
        commissionRate: commission.commissionRate,
        commissionAmount: commission.commissionAmount,
        isPaid: true,
        month: commission.month,
        adminId: commission.adminId,
      );
      notifyListeners();
    }
  }
}
