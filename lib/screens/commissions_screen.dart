import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/firestore_service.dart';

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<RestaurantCommission> _commissions = [];
  bool _isLoading = true;

  // Summary totals
  double _totalRevenue = 0;
  double _totalCommission = 0;
  double _paidCommission = 0;
  double _pendingCommission = 0;

  // Filter
  String _selectedMonth = _currentMonthLabel();
  final List<String> _months = _generateMonths();

  static String _currentMonthLabel() {
    final now = DateTime.now();
    return '${_monthName(now.month)} ${now.year}';
  }

  static List<String> _generateMonths() {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i);
      months.add('${_monthName(d.month)} ${d.year}');
    }
    return months;
  }

  static String _monthName(int month) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);
    try {
      final String? adminId = FirebaseAuth.instance.currentUser?.uid;
      
      final monthIndex = _months.indexOf(_selectedMonth);
      final now = DateTime.now();
      final targetDate = DateTime(now.year, now.month - monthIndex);
      final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 1);

      final commissionData = await FirestoreService().getCommissionData(adminId, startOfMonth, endOfMonth);

      final List<RestaurantCommission> list = commissionData.map((data) => RestaurantCommission(
        restaurantId: data[FirestoreConstants.restaurantId],
        restaurantName: data[FirestoreConstants.restaurantName],
        totalOrders: data[FirestoreConstants.totalOrders],
        totalRevenue: data[FirestoreConstants.totalRevenue]?.toDouble() ?? 0.0,
        commissionRate: data[FirestoreConstants.commissionRate]?.toDouble() ?? 0.0,
        commissionAmount: data[FirestoreConstants.commissionAmount]?.toDouble() ?? 0.0,
        isPaid: data[FirestoreConstants.isPaid] ?? false,
        month: data[FirestoreConstants.month],
      )).toList();

      list.sort((a, b) => b.commissionAmount.compareTo(a.commissionAmount));

      double rev = 0, comm = 0, paid = 0, pending = 0;
      for (var c in list) {
        rev += c.totalRevenue;
        comm += c.commissionAmount;
        if (c.isPaid) {
          paid += c.commissionAmount;
        } else {
          pending += c.commissionAmount;
        }
      }

      setState(() {
        _commissions = list;
        _totalRevenue = rev;
        _totalCommission = comm;
        _paidCommission = paid;
        _pendingCommission = pending;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error loading commissions: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Future<void> _markAsPaid(RestaurantCommission commission) async {
    try {
      final docId = '${commission.restaurantId}_${commission.month.year}_${commission.month.month}';
      final data = {
        FirestoreConstants.restaurantId: commission.restaurantId,
        FirestoreConstants.restaurantName: commission.restaurantName,
        FirestoreConstants.month: commission.month.month,
        FirestoreConstants.year: commission.month.year,
        FirestoreConstants.totalRevenue: commission.totalRevenue,
        FirestoreConstants.commissionRate: commission.commissionRate,
        FirestoreConstants.commissionAmount: commission.commissionAmount,
        FirestoreConstants.totalOrders: commission.totalOrders,
        FirestoreConstants.isPaid: true,
        FirestoreConstants.paidAt: FieldValue.serverTimestamp(),
      };
      
      await FirestoreService().markCommissionAsPaid(docId, data);

      if (!mounted) return;
      _showSnack('Commission marked as paid ✓');
      _loadCommissions();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _updateCommissionRate(RestaurantCommission commission) async {
    final controller = TextEditingController(text: commission.commissionRate.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
        title: Text('Commission rate — ${commission.restaurantName}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Rate (%)',
            labelStyle: TextStyle(color: AppColors.subtle),
            suffixText: '%',
            suffixStyle: TextStyle(color: AppColors.subtle),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.subtle))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(100, 45), // Already has a good size, but keeping consistency
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0 && v <= 100) Navigator.pop(ctx, v);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      await FirestoreService().updateRestaurant(commission.restaurantId, {FirestoreConstants.commissionRate: result});
      if (!mounted) return;
      _showSnack('Rate updated to ${result.toStringAsFixed(0)}%');
      _loadCommissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          key: isMobile ? GlobalKey<ScaffoldState>() : null,
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Commissions')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  title: const Text("Commissions", style: TextStyle(color: Colors.white, fontSize: 18)),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadCommissions,
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              // Sidebar
              if (!isMobile) const AdminSidebar(activeItem: 'Commissions'),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Header & Tabs
                    if (!isMobile)
                      Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Commissions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 4),
                                Text("Track restaurant payouts and platform service fees.", style: TextStyle(fontSize: 14, color: AppColors.subtle)),
                              ],
                            ),
                            const Spacer(),
                            TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              indicatorColor: AppColors.primary,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.subtle,
                              indicatorWeight: 3,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabAlignment: TabAlignment.start,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'BY RESTAURANT'),
                                Tab(text: 'PAYMENT HISTORY'),
                              ],
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.refresh_outlined, color: AppColors.subtle),
                              onPressed: _loadCommissions,
                            ),
                          ],
                        ),
                      ),
                    if (isMobile)
                      Container(
                        color: AppColors.card,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primary,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.subtle,
                          tabs: const [
                            Tab(text: 'RESTAURANTS'),
                            Tab(text: 'HISTORY'),
                          ],
                        ),
                      ),
                    // Body
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildByRestaurantTab(isMobile),
                                _buildHistoryTab(isMobile),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildByRestaurantTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters & Summary Row
          if (isMobile) ...[
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildMobileSummary(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(width: 24),
                Expanded(child: _buildDesktopSummary()),
              ],
            ),
          const SizedBox(height: 32),

          // Collection Progress
          if (_totalCommission > 0) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Collection progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('${(_paidCommission / _totalCommission * 100).toStringAsFixed(1)}% collected',
                          style: const TextStyle(fontSize: 14, color: AppColors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalCommission > 0 ? _paidCommission / _totalCommission : 0,
                      minHeight: 10,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // List
          const Text('Restaurant Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),

          if (_commissions.isEmpty)
            _EmptyState(message: 'No delivered orders found for $_selectedMonth')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _CommissionCard(
                isMobile: isMobile,
                commission: _commissions[i],
                onMarkPaid: () => _markAsPaid(_commissions[i]),
                onEditRate: () => _updateCommissionRate(_commissions[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: _selectedMonth,
        isExpanded: true,
        dropdownColor: AppColors.card,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _selectedMonth = v);
            _loadCommissions();
          }
        },
      ),
    );
  }

  Widget _buildDesktopSummary() {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'TOTAL REVENUE', value: 'Rs ${_fmt(_totalRevenue)}', icon: Icons.account_balance_wallet_outlined, color: Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(label: 'COMMISSION', value: 'Rs ${_fmt(_totalCommission)}', icon: Icons.payments_outlined, color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(label: 'PAID', value: 'Rs ${_fmt(_paidCommission)}', icon: Icons.check_circle_outline, color: AppColors.green)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(label: 'PENDING', value: 'Rs ${_fmt(_pendingCommission)}', icon: Icons.hourglass_empty_outlined, color: AppColors.amber)),
      ],
    );
  }

  Widget _buildMobileSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'REVENUE', value: 'Rs ${_fmt(_totalRevenue)}', icon: Icons.account_balance_wallet_outlined, color: Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'COMMISSION', value: 'Rs ${_fmt(_totalCommission)}', icon: Icons.payments_outlined, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'PAID', value: 'Rs ${_fmt(_paidCommission)}', icon: Icons.check_circle_outline, color: AppColors.green)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'PENDING', value: 'Rs ${_fmt(_pendingCommission)}', icon: Icons.hourglass_empty_outlined, color: AppColors.amber)),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab(bool isMobile) {
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getCommissionHistory(adminId: adminId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyState(message: 'No commission payment history yet');
        }

        final history = snapshot.data!;

        return ListView.separated(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final data = history[i];
            final isPaid = data[FirestoreConstants.isPaid] == true;
            final monthLabel = '${_monthName(data[FirestoreConstants.month] ?? 1)} ${data[FirestoreConstants.year] ?? ''}';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.green.withValues(alpha: 0.1) : AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                      color: isPaid ? AppColors.green : AppColors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data[FirestoreConstants.restaurantName] ?? 'Unknown', style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('$monthLabel • ${data[FirestoreConstants.totalOrders] ?? 0} orders • ${data[FirestoreConstants.commissionRate]?.toStringAsFixed(0) ?? 15}% rate',
                            style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs ${(data[FirestoreConstants.commissionAmount] ?? 0).toDouble().toStringAsFixed(0)}',
                          style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      _PillBadge(label: isPaid ? 'Paid' : 'Pending', isPaid: isPaid),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Commission Card ─────────────────────────────────────────────────────────
class _CommissionCard extends StatelessWidget {
  final bool isMobile;
  final RestaurantCommission commission;
  final VoidCallback onMarkPaid;
  final VoidCallback onEditRate;

  const _CommissionCard({required this.isMobile, required this.commission, required this.onMarkPaid, required this.onEditRate});

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: commission.isPaid ? AppColors.green.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(commission.restaurantName,
                    style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              _PillBadge(label: commission.isPaid ? 'Paid' : 'Pending', isPaid: commission.isPaid),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _Stat(label: 'Orders', value: '${commission.totalOrders}'),
              _Stat(label: 'Revenue', value: 'Rs ${_fmt(commission.totalRevenue)}'),
              _Stat(label: 'Rate', value: '${commission.commissionRate.toStringAsFixed(0)}%'),
              _Stat(label: 'Commission', value: 'Rs ${_fmt(commission.commissionAmount)}', highlight: true),
            ],
          ),

          // Commission bar
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: commission.totalRevenue > 0 ? commission.commissionAmount / commission.totalRevenue : 0,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                commission.isPaid ? AppColors.green : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditRate,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(isMobile ? 'Rate' : 'Edit rate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(0, 50), // Override global infinity width
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: commission.isPaid
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.green),
                            SizedBox(width: 8),
                            Text('Paid', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: onMarkPaid,
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: Text(isMobile ? 'Mark' : 'Mark as Paid', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(0, 50), // Override global infinity width
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small stat cell ─────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _Stat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.subtle, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.primary : Colors.white,
          )),
        ],
      ),
    );
  }
}

// ── Summary Card ────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.subtle)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Pill Badge ───────────────────────────────────────────────────────────────
class _PillBadge extends StatelessWidget {
  final String label;
  final bool isPaid;
  const _PillBadge({required this.label, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (isPaid ? AppColors.green : AppColors.amber).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isPaid ? AppColors.green : AppColors.amber,
      )),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.subtle, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Data Model ──────────────────────────────────────────────────────────────
class RestaurantCommission {
  final String restaurantId;
  final String restaurantName;
  final int totalOrders;
  final double totalRevenue;
  final double commissionRate;
  final double commissionAmount;
  final bool isPaid;
  final DateTime month;

  RestaurantCommission({
    required this.restaurantId,
    required this.restaurantName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.commissionRate,
    required this.commissionAmount,
    required this.isPaid,
    required this.month,
  });
}


