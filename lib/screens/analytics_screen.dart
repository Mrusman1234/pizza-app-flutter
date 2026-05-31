import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add fl_chart to pubspec.yaml:
//   dependencies:
//     fl_chart: ^0.68.0
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabs;

  // Filter
  String _range = 'This Month';
  final List<String> _ranges = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];

  // ── Revenue chart data (daily or monthly)
  List<_ChartPoint> _revenuePoints = [];

  // ── Order status breakdown
  int _delivered = 0, _pending = 0, _cancelled = 0, _onTheWay = 0;

  // ── Top restaurants
  List<_RestaurantStat> _topRestaurants = [];

  // ── Top pizzas
  List<_ItemStat> _topItems = [];

  // ── Summary KPIs
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgOrderValue = 0;
  int _newCustomers = 0;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Date range helpers ────────────────────────────────────────────────────
  DateTimeRange _getRange() {
    final now = DateTime.now();
    switch (_range) {
      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: DateTime(start.year, start.month, start.day), end: now);
      case 'Last 3 Months':
        return DateTimeRange(start: DateTime(now.year, now.month - 2, 1), end: now);
      case 'This Year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      default: // This Month
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  bool _isMonthlyGrouping() => _range == 'Last 3 Months' || _range == 'This Year';

  // ── Load all data ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final String? adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'User not authenticated';
          });
        }
        return;
      }

      final range = _getRange();
      final start = Timestamp.fromDate(range.start);
      final end = Timestamp.fromDate(range.end);

      // ── Fetch Orders for this Admin within Date Range
      // Note: This query may require a composite index: adminId ASC, createdAt ASC
      final snap = await _db
          .collection(FirestoreConstants.orders)
          .where(FirestoreConstants.adminId, isEqualTo: adminId)
          .where(FirestoreConstants.createdAt, isGreaterThanOrEqualTo: start)
          .where(FirestoreConstants.createdAt, isLessThanOrEqualTo: end)
          .get();
      
      if (!mounted) return;

      final docs = snap.docs.map((d) => d.data()).toList();

      // ── KPIs
      double rev = 0;
      int delivered = 0, pending = 0, cancelled = 0, onTheWay = 0;
      final Map<String, double> restaurantRev = {};
      final Map<String, int> restaurantOrders = {};
      final Map<String, String> restaurantNames = {};
      final Map<String, int> itemCount = {};

      // Revenue grouped by day or month
      final Map<String, double> grouped = {};

      for (final data in docs) {
        final amount = (data[FirestoreConstants.totalAmount] ?? 0).toDouble();
        final status = (data[FirestoreConstants.status] ?? '').toString().toLowerCase();
        rev += amount;
        if (status == FirestoreConstants.statusDelivered.toLowerCase()) {
          delivered++;
        } else if (status == FirestoreConstants.statusPending.toLowerCase()) {
          pending++;
        } else if (status == FirestoreConstants.statusCancelled.toLowerCase()) {
          cancelled++;
        } else if (status == FirestoreConstants.statusOnTheWay.toLowerCase()) {
          onTheWay++;
        }

        // Restaurant stats
        final rId = data[FirestoreConstants.restaurantId] ?? '';
        final rName = data[FirestoreConstants.restaurantName] ?? 'Unknown';
        if (rId.isNotEmpty) {
          restaurantRev[rId] = (restaurantRev[rId] ?? 0) + amount;
          restaurantOrders[rId] = (restaurantOrders[rId] ?? 0) + 1;
          restaurantNames[rId] = rName;
        }

        // Item stats
        final items = data[FirestoreConstants.items] as List<dynamic>? ?? [];
        for (final item in items) {
          final name = item[FirestoreConstants.name]?.toString() ?? 'Unknown';
          final qty = (item[FirestoreConstants.quantity] ?? 1) as int;
          itemCount[name] = (itemCount[name] ?? 0) + qty;
        }

        // Revenue grouping
        final ts = data[FirestoreConstants.createdAt] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          final key = _isMonthlyGrouping()
              ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
              : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          grouped[key] = (grouped[key] ?? 0) + amount;
        }
      }

      // Build chart points (sorted)
      final sortedKeys = grouped.keys.toList()..sort();
      final points = sortedKeys.asMap().entries.map((e) {
        return _ChartPoint(x: e.key.toDouble(), y: grouped[e.value] ?? 0, label: _formatKey(e.value));
      }).toList();

      // Top restaurants (top 5)
      final topR = restaurantRev.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topRestaurants = topR.take(5).map((e) => _RestaurantStat(
        name: restaurantNames[e.key] ?? e.key,
        revenue: e.value,
        orders: restaurantOrders[e.key] ?? 0,
        maxRevenue: topR.isEmpty ? 0 : topR.first.value,
      )).toList();

      // Top items (top 6)
      final topI = itemCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topItems = topI.take(6).map((e) => _ItemStat(name: e.key, count: e.value)).toList();

      // ── Calculate unique customers for this admin in this period
      final uniqueUserIds = docs.map((d) => d[FirestoreConstants.userId] as String?).whereType<String>().toSet();

      setState(() {
        _totalRevenue = rev;
        _totalOrders = docs.length;
        _avgOrderValue = docs.isEmpty ? 0 : rev / docs.length;
        _delivered = delivered;
        _pending = pending;
        _cancelled = cancelled;
        _onTheWay = onTheWay;
        _revenuePoints = points;
        _topRestaurants = topRestaurants;
        _topItems = topItems;
        _newCustomers = uniqueUserIds.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load analytics data: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatKey(String key) {
    final parts = key.split('-');
    if (parts.length == 2) {
      const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return months[int.parse(parts[1])];
    }
    return parts.last; // day number
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeItem: 'Analytics'),
          Expanded(
            child: Column(
              children: [
                // Header & Tabs
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isCompact = constraints.maxWidth < 800;
                      
                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Analytics", 
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh, color: AppColors.subtle),
                                ),
                              ],
                            ),
                            const Text(
                              "Detailed insights into sales, orders, and growth.", 
                              style: TextStyle(fontSize: 14, color: AppColors.subtle),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            TabBar(
                              controller: _tabs,
                              isScrollable: true,
                              indicatorColor: AppColors.primary,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.subtle,
                              indicatorWeight: 3,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabAlignment: TabAlignment.start,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'REVENUE'),
                                Tab(text: 'ORDERS'),
                                Tab(text: 'TOP ITEMS'),
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Analytics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 4),
                                Text(
                                  "Detailed insights into sales, orders, and growth.", 
                                  style: TextStyle(fontSize: 14, color: AppColors.subtle),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TabBar(
                              controller: _tabs,
                              isScrollable: true,
                              indicatorColor: AppColors.primary,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.subtle,
                              indicatorWeight: 3,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabAlignment: TabAlignment.start,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'REVENUE'),
                                Tab(text: 'ORDERS'),
                                Tab(text: 'TOP ITEMS'),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh, color: AppColors.subtle),
                          ),
                        ],
                      );
                    }
                  ),
                ),
                Expanded(
                        child: Column(
                          children: [
                            // Range filter
                            Container(
                              color: AppColors.background,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _ranges.map((r) {
                                    final active = r == _range;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => _range = r);
                                        _load();
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: active ? AppColors.primary : AppColors.card,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1),
                                        ),
                                        child: Text(r,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: active ? Colors.white : AppColors.subtle,
                                            )),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            // KPI row
                            Container(
                              color: AppColors.background,
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                              child: Row(
                                children: [
                                  _KpiTile(label: 'Revenue', value: 'Rs ${_fmtK(_totalRevenue)}', color: AppColors.primary),
                                  _KpiTile(label: 'Orders', value: '$_totalOrders', color: Colors.blueAccent),
                                  _KpiTile(
                                      label: 'Avg order',
                                      value: 'Rs ${_totalOrders == 0 ? 0 : _avgOrderValue.toStringAsFixed(0)}',
                                      color: AppColors.green),
                                  _KpiTile(label: 'Customers', value: '$_newCustomers', color: Colors.purpleAccent),
                                ],
                              ),
                            ),

                            Expanded(
                              child: _loading 
                                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                  : _errorMessage != null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                          const SizedBox(height: 16),
                                          Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            onPressed: _load,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              minimumSize: const Size(120, 45), // Override global infinity width
                                            ),
                                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    )
                                  : TabBarView(
                                controller: _tabs,
                                children: [
                                  _buildRevenueTab(),
                                  _buildOrdersTab(),
                                  _buildItemsTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Revenue ────────────────────────────────────────────────────────
  Widget _buildRevenueTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Revenue trend — $_range'),
            const SizedBox(height: 12),
            _ChartCard(
              child: _revenuePoints.isEmpty
                  ? _noData()
                  : SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (v, _) => Text(
                                  'Rs ${_fmtK(v)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: _revenuePoints.length > 10 ? (_revenuePoints.length / 6).ceilToDouble() : 1,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= _revenuePoints.length) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(_revenuePoints[i].label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _revenuePoints.map((p) => FlSpot(p.x, p.y)).toList(),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0)],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) => AppColors.card2,
                              getTooltipItems: (spots) => spots.map((s) {
                                final label = s.x.toInt() < _revenuePoints.length ? _revenuePoints[s.x.toInt()].label : '';
                                return LineTooltipItem(
                                  '$label\nRs ${s.y.toStringAsFixed(0)}',
                                  const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Top restaurants by revenue'),
            const SizedBox(height: 12),
            if (_topRestaurants.isEmpty)
              _ChartCard(child: _noData())
            else
              _ChartCard(
                child: Column(
                  children: _topRestaurants.map((r) => _RestaurantBar(stat: r)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Orders ─────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    final total = _delivered + _pending + _cancelled + _onTheWay;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Order status breakdown'),
          const SizedBox(height: 12),
          _ChartCard(
            child: total == 0
                ? _noData()
                : Row(
                    children: [
                      SizedBox(
                        width: 150, height: 150,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 35,
                            sections: [
                              if (_delivered > 0) PieChartSectionData(value: _delivered.toDouble(), color: AppColors.green, title: '', radius: 45),
                              if (_pending > 0)   PieChartSectionData(value: _pending.toDouble(),   color: AppColors.amber, title: '', radius: 45),
                              if (_onTheWay > 0)  PieChartSectionData(value: _onTheWay.toDouble(),  color: Colors.blueAccent, title: '', radius: 45),
                              if (_cancelled > 0) PieChartSectionData(value: _cancelled.toDouble(), color: AppColors.primary, title: '', radius: 45),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Legend(color: AppColors.green, label: 'Delivered', count: _delivered, total: total),
                            const SizedBox(height: 12),
                            _Legend(color: AppColors.amber, label: 'Pending',   count: _pending,   total: total),
                            const SizedBox(height: 12),
                            _Legend(color: Colors.blueAccent, label: 'On the way',count: _onTheWay,  total: total),
                            const SizedBox(height: 12),
                            _Legend(color: AppColors.primary, label: 'Cancelled', count: _cancelled, total: total),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          _SectionTitle('Orders by restaurant'),
          const SizedBox(height: 12),
          if (_topRestaurants.isEmpty)
            _ChartCard(child: _noData())
          else
            _ChartCard(
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= _topRestaurants.length) return const SizedBox();
                            final name = _topRestaurants[i].name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.length > 8 ? '${name.substring(0, 7)}…' : name,
                                style: const TextStyle(fontSize: 10, color: AppColors.muted),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 32,
                          getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: _topRestaurants.asMap().entries.map((e) =>
                      BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(
                          toY: e.value.orders.toDouble(),
                          color: Colors.blueAccent,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ]),
                    ).toList(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.card2,
                        getTooltipItem: (group, rodIndex, rod, entryIndex) => BarTooltipItem(
                          '${_topRestaurants[group.x].name}\n${rod.toY.toInt()} orders',
                          const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 3: Top Items ──────────────────────────────────────────────────────
  Widget _buildItemsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Best selling items — $_range'),
          const SizedBox(height: 12),
          if (_topItems.isEmpty)
            _ChartCard(child: _noData())
          else ...[
            _ChartCard(
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= _topItems.length) return const SizedBox();
                            final name = _topItems[i].name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.length > 8 ? '${name.substring(0, 7)}…' : name,
                                style: const TextStyle(fontSize: 10, color: AppColors.muted),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 28,
                          getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: _topItems.asMap().entries.map((e) =>
                      BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(
                          toY: e.value.count.toDouble(),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF6B6B)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ]),
                    ).toList(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.card2,
                        getTooltipItem: (group, rodIndex, rod, entryIndex) => BarTooltipItem(
                          '${_topItems[group.x].name}\n${rod.toY.toInt()} sold',
                          const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Item details'),
            const SizedBox(height: 12),
            _ChartCard(
              child: Column(
                children: _topItems.asMap().entries.map((e) {
                  final maxCount = _topItems.first.count;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.value.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                                  Text('${e.value.count} sold', style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: maxCount > 0 ? e.value.count / maxCount : 0,
                                  minHeight: 6,
                                  backgroundColor: AppColors.background,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noData() => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: Text('No data for this period', style: TextStyle(color: AppColors.muted, fontSize: 14))),
  );

  String _fmtK(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _KpiTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text));
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border, width: 1),
    ),
    child: child,
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count, total;
  const _Legend({required this.color, required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.subtle))),
        Text('$count ($pct%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text)),
      ],
    );
  }
}

class _RestaurantBar extends StatelessWidget {
  final _RestaurantStat stat;
  const _RestaurantBar({required this.stat});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text(stat.name, style: const TextStyle(fontSize: 13, color: AppColors.text), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stat.maxRevenue > 0 ? stat.revenue / stat.maxRevenue : 0,
              minHeight: 12,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            'Rs ${stat.revenue >= 1000 ? '${(stat.revenue / 1000).toStringAsFixed(1)}K' : stat.revenue.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _ChartPoint {
  final double x, y;
  final String label;
  const _ChartPoint({required this.x, required this.y, required this.label});
}

class _RestaurantStat {
  final String name;
  final double revenue, maxRevenue;
  final int orders;
  const _RestaurantStat({required this.name, required this.revenue, required this.orders, required this.maxRevenue});
}

class _ItemStat {
  final String name;
  final int count;
  const _ItemStat({required this.name, required this.count});
}


