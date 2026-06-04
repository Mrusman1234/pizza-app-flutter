import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id; // Usually the userId or restaurantId
  final double balance;
  final double totalEarned;
  final double totalWithdrawn;
  final DateTime lastUpdated;

  WalletModel({
    required this.id,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'lastUpdated': lastUpdated,
    };
  }

  factory WalletModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletModel(
      id: id,
      balance: (map['balance'] as num? ?? 0.0).toDouble(),
      totalEarned: (map['totalEarned'] as num? ?? 0.0).toDouble(),
      totalWithdrawn: (map['totalWithdrawn'] as num? ?? 0.0).toDouble(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum TransactionType { earnings, withdrawal, refund, adjustment }

class WalletTransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String description;
  final String? orderId;
  final DateTime timestamp;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.orderId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.name,
      'description': description,
      'orderId': orderId,
      'timestamp': timestamp,
    };
  }

  factory WalletTransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletTransactionModel(
      id: id,
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.earnings,
      ),
      description: map['description'] ?? '',
      orderId: map['orderId'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
