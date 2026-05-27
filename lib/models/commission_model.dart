import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionModel {
  final String? id;
  final String restaurantId;
  final String restaurantName;
  final int totalOrders;
  final double totalRevenue;
  final double commissionRate;
  final double commissionAmount;
  final bool isPaid;
  final DateTime month;
  final String? adminId;

  CommissionModel({
    this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.commissionRate,
    required this.commissionAmount,
    required this.isPaid,
    required this.month,
    this.adminId,
  });

  factory CommissionModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CommissionModel(
      id: documentId,
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      totalOrders: map['totalOrders'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      commissionRate: (map['commissionRate'] ?? 0).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      month: (map['month'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminId: map['adminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'isPaid': isPaid,
      'month': Timestamp.fromDate(month),
      'adminId': adminId,
    };
  }
}
