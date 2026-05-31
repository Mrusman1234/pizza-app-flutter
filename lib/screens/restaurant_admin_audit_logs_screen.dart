// lib/screens/restaurant_admin_audit_logs_screen.dart
//
// Shows the audit trail for the admin's own restaurant.
// Read-only — no mutations here.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/restaurant_admin_provider.dart';
import '../services/audit_service.dart';

class RestaurantAdminAuditLogsScreen extends StatelessWidget {
  const RestaurantAdminAuditLogsScreen({super.key});

  Color _colorForAction(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('order'))  return Colors.blueAccent;
    if (lowerAction.contains('menu'))   return AppColors.green;
    if (lowerAction.contains('admin'))  return AppColors.amber;
    return AppColors.subtle;
  }

  IconData _iconForAction(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('order'))  return Icons.receipt_long_rounded;
    if (lowerAction.contains('menu'))   return Icons.restaurant_menu_rounded;
    if (lowerAction.contains('admin'))  return Icons.person_rounded;
    return Icons.history_rounded;
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = context.read<RestaurantAdminProvider>().restaurantId;
    final audit = AuditService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: const Text('Audit Logs',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: audit.getLogsForRestaurant(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      color: AppColors.subtle, size: 48),
                  SizedBox(height: 12),
                  Text('No audit logs yet',
                      style: TextStyle(color: AppColors.subtle)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final log = logs[i];
              final action = log['action'] as String? ?? '';
              final color = _colorForAction(action);
              final icon = _iconForAction(action);
              final target = log['target'] as String? ?? '';
              final email = log['adminEmail'] as String? ?? '';
              final ts = log['timestamp'];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.replaceAll('_', ' '),
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(target,
                              style: const TextStyle(
                                  color: AppColors.subtle, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(
                                  color: AppColors.subtle, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      _formatTimestamp(ts),
                      style: const TextStyle(
                          color: AppColors.subtle, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
