import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      final userId = auth.user?.uid;
      final restId = auth.user?.assignedRestaurantId;
      
      // Use restaurantId if it's a restaurant admin, otherwise use userId (for riders)
      final targetId = (auth.user?.role == 'restaurant_admin') ? restId : userId;
      
      if (targetId != null) {
        context.read<WalletProvider>().listenToWallet(targetId);
      }
    });
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    String method = 'JazzCash';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Withdrawal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (Rs.)',
                  labelStyle: const TextStyle(color: AppColors.subtle),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Payment Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _methodChip('JazzCash', method, (val) => setModalState(() => method = val)),
                  const SizedBox(width: 12),
                  _methodChip('EasyPaisa', method, (val) => setModalState(() => method = val)),
                  const SizedBox(width: 12),
                  _methodChip('Bank', method, (val) => setModalState(() => method = val)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Account Details (Title & Number)',
                  labelStyle: const TextStyle(color: AppColors.subtle),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) return;
                    
                    setModalState(() => isSubmitting = true);
                    try {
                      final auth = context.read<AppAuthProvider>();
                      final targetId = (auth.user?.role == 'restaurant_admin') 
                        ? auth.user!.assignedRestaurantId! 
                        : auth.user!.uid;

                      await context.read<WalletProvider>().requestWithdrawal(
                        id: targetId,
                        amount: amount,
                        method: method,
                        details: detailsController.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
                      }
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Confirm Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodChip(String label, String selected, Function(String) onSelect) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.subtle, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final wallet = provider.wallet;
    final transactions = provider.transactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Earnings'),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final auth = context.read<AppAuthProvider>();
                final id = (auth.user?.role == 'restaurant_admin') ? auth.user?.assignedRestaurantId : auth.user?.uid;
                if (id != null) provider.listenToWallet(id);
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: _buildBalanceCard(wallet),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  if (transactions.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('No transactions yet.', style: TextStyle(color: AppColors.subtle))),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTransactionTile(transactions[index]),
                        childCount: transactions.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(WalletModel? wallet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Text('CURRENT BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Rs. ${wallet?.balance.toStringAsFixed(0) ?? '0'}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _balanceSubItem('Total Earned', 'Rs. ${wallet?.totalEarned.toStringAsFixed(0) ?? '0'}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _balanceSubItem('Withdrawn', 'Rs. ${wallet?.totalWithdrawn.toStringAsFixed(0) ?? '0'}'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (wallet?.balance ?? 0) >= 500 ? _showWithdrawDialog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if ((wallet?.balance ?? 0) < 500)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Minimum Rs. 500 required to withdraw', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _balanceSubItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionTile(WalletTransactionModel txn) {
    final isPositive = txn.amount > 0;
    final color = isPositive ? AppColors.green : Colors.redAccent;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
              txn.type == TransactionType.earnings ? Icons.add_chart : Icons.account_balance_wallet,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy • hh:mm a').format(txn.timestamp), style: const TextStyle(color: AppColors.subtle, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}Rs. ${txn.amount.abs().toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
