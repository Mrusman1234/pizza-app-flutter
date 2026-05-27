import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../providers/order_provider.dart';
import '../../routes/route_names.dart';

class OrderTrackingCard extends StatelessWidget {
  const OrderTrackingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final activeOrder = orderProvider.activeOrder;
        
        if (activeOrder == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context, 
            RouteNames.orderDetails, 
            arguments: activeOrder.id,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusMessage(activeOrder.status),
                            style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${activeOrder.items.first.pizza.name} · Rs. ${activeOrder.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Text('8', style: TextStyle(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.w500)),
                          Text('min away', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTrackerSteps(activeOrder.status),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case FirestoreConstants.statusPending:
        return '⌛ Order Received';
      case FirestoreConstants.statusPreparing:
        return '👨‍🍳 Being Prepared';
      case FirestoreConstants.statusOnTheWay:
        return '🛵 Your order is on the way!';
      default:
        return '📦 Order Update';
    }
  }

  Widget _buildTrackerSteps(String currentStatus) {
    final steps = [
      {'icon': Icons.check,              'label': 'Order\nConfirmed', 'status': FirestoreConstants.statusPending},
      {'icon': Icons.restaurant,         'label': 'Being\nPrepared',  'status': FirestoreConstants.statusPreparing},
      {'icon': Icons.directions_bike,    'label': 'On the\nWay',      'status': FirestoreConstants.statusOnTheWay},
      {'icon': Icons.home_outlined,      'label': 'Delivered',        'status': FirestoreConstants.statusDelivered},
    ];

    int currentStepIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentStatus == FirestoreConstants.statusPending) currentStepIndex = 0; 

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isDone = currentStepIndex > stepIdx;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 24),
              color: isDone ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step    = steps[stepIdx];
        final icon    = step['icon'] as IconData;
        final label   = step['label'] as String;
        final status  = step['status'] as String;

        final bool isDone   = currentStepIndex > stepIdx || (currentStatus == FirestoreConstants.statusDelivered && status == FirestoreConstants.statusDelivered);
        final bool isActive = currentStepIndex == stepIdx && currentStatus != FirestoreConstants.statusDelivered;

        final circleBg    = isDone ? AppColors.primary : AppColors.card;
        final iconColor   = isDone ? Colors.white : isActive ? AppColors.primary : AppColors.muted;
        final borderColor = (isDone || isActive) ? AppColors.primary : AppColors.border;
        final labelColor  = isDone ? AppColors.primary : isActive ? AppColors.text : AppColors.muted;

        return Column(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: labelColor, fontSize: 9, height: 1.3)),
          ],
        );
      }),
    );
  }
}
