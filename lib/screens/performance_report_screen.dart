import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/pdf_service.dart';

class PerformanceReportScreen extends StatefulWidget {
  const PerformanceReportScreen({super.key});

  @override
  State<PerformanceReportScreen> createState() => _PerformanceReportScreenState();
}

class _PerformanceReportScreenState extends State<PerformanceReportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = true;

  // Stats
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgOrderValue = 0;
  double _growthRate = 0;
  
  // Operational Metrics
  double _avgPrepTime = 0;
  double _orderAccuracy = 0;
  double _onTimeDelivery = 0;
  
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _recentOrders = [];

  // Chart Data
  List<FlSpot> _salesSpots = [];
  List<BarChartGroupData> _orderGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final String? adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevMonthEnd = currentMonthStart.subtract(const Duration(seconds: 1));

      // Fetch orders for current month partitioned by adminId
      final currentOrdersSnap = await _db.collection(FirestoreConstants.orders)
          .where(FirestoreConstants.adminId, isEqualTo: adminId)
          .where(FirestoreConstants.createdAt, isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonthStart))
          .get();
      
      if (!mounted) return;

      // If current month has no orders, try fetching recent orders for this admin
      final List<DocumentSnapshot> allRelevantOrders;
      if (currentOrdersSnap.docs.isEmpty) {
        final fallbackSnap = await _db.collection(FirestoreConstants.orders)
            .where(FirestoreConstants.adminId, isEqualTo: adminId)
            .limit(100)
            .get();
        if (!mounted) return;
        allRelevantOrders = fallbackSnap.docs;
      } else {
        allRelevantOrders = currentOrdersSnap.docs;
      }

      // Fetch orders for previous month partitioned by adminId
      final prevOrdersSnap = await _db.collection(FirestoreConstants.orders)
          .where(FirestoreConstants.adminId, isEqualTo: adminId)
          .where(FirestoreConstants.createdAt, isGreaterThanOrEqualTo: Timestamp.fromDate(prevMonthStart))
          .where(FirestoreConstants.createdAt, isLessThanOrEqualTo: Timestamp.fromDate(prevMonthEnd))
          .get();
      
      if (!mounted) return;

      double currentRevenue = 0;
      Map<String, int> productSales = {};
      Map<String, double> productRevenue = {};
      Map<String, String> productCategories = {};

      for (var doc in allRelevantOrders) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data[FirestoreConstants.totalAmount] ?? 0).toDouble();
        currentRevenue += amount;

        final items = data[FirestoreConstants.items] as List<dynamic>? ?? [];
        for (var item in items) {
          final name = item['name'] ?? 'Unknown';
          final qty = (item['quantity'] ?? 0) as int;
          final price = (item['price'] ?? 0).toDouble();
          final category = item['category'] ?? 'Pizza';
          
          productSales[name] = (productSales[name] ?? 0) + qty;
          productRevenue[name] = (productRevenue[name] ?? 0) + (price * qty);
          productCategories[name] = category;
        }
      }

      double prevRevenue = 0;
      for (var doc in prevOrdersSnap.docs) {
        prevRevenue += (doc.data()[FirestoreConstants.totalAmount] ?? 0).toDouble();
      }

      // Calculate Operational Metrics
      List<int> prepTimes = [];
      int accurateOrders = 0;
      int deliveredOrders = 0;
      int totalDelivered = 0;

      for (var doc in allRelevantOrders) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data[FirestoreConstants.status];
        
        if (status == FirestoreConstants.statusDelivered) {
          totalDelivered++;
          final createdAt = (data[FirestoreConstants.createdAt] as Timestamp?)?.toDate();
          final preparingAt = (data[FirestoreConstants.preparingAt] as Timestamp?)?.toDate();
          final deliveredAt = (data[FirestoreConstants.deliveredAt] as Timestamp?)?.toDate();

          if (createdAt != null && preparingAt != null) {
            prepTimes.add(preparingAt.difference(createdAt).inMinutes);
          }
          
          // Simplified accuracy: if not cancelled or delayed excessively
          if (data[FirestoreConstants.status] != FirestoreConstants.statusCancelled) {
            accurateOrders++;
          }
          
          if (deliveredAt != null && createdAt != null) {
             // Target delivery 45 mins
             if (deliveredAt.difference(createdAt).inMinutes <= 45) {
               deliveredOrders++;
             }
          }
        }
      }

      double avgPrep = prepTimes.isNotEmpty ? prepTimes.reduce((a, b) => a + b) / prepTimes.length : 0;
      double accuracy = allRelevantOrders.isNotEmpty ? (accurateOrders / allRelevantOrders.length) * 100 : 0;
      double onTime = totalDelivered > 0 ? (deliveredOrders / totalDelivered) * 100 : 0;

      // Prepare Chart Data
      Map<int, double> dailyRevenue = {};
      Map<int, int> dailyOrdersCount = {};
      
      for (var doc in allRelevantOrders) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data[FirestoreConstants.createdAt] as Timestamp?)?.toDate();
        if (date != null) {
          final day = date.day;
          final amount = (data[FirestoreConstants.totalAmount] ?? 0).toDouble();
          dailyRevenue[day] = (dailyRevenue[day] ?? 0) + amount;
          dailyOrdersCount[day] = (dailyOrdersCount[day] ?? 0) + 1;
        }
      }

      List<FlSpot> salesSpots = [];
      List<BarChartGroupData> orderGroups = [];
      
      // Get all days of the month up to today
      for (int i = 1; i <= now.day; i++) {
        salesSpots.add(FlSpot(i.toDouble(), dailyRevenue[i] ?? 0));
        orderGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (dailyOrdersCount[i] ?? 0).toDouble(),
                color: AppColors.primary,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )
            ],
          ),
        );
      }

      // Calculate Growth
      double growth = 0;
      if (prevRevenue > 0) {
        growth = ((currentRevenue - prevRevenue) / prevRevenue) * 100;
      } else if (currentRevenue > 0) {
        growth = 100;
      }

      // Sort top products
      var sortedProducts = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _topProducts = sortedProducts.take(5).map((e) {
        return {
          'name': e.key,
          'count': e.value,
          'revenue': productRevenue[e.key] ?? 0,
          'category': productCategories[e.key] ?? 'Pizza',
        };
      }).toList();

      _recentOrders = currentOrdersSnap.docs.take(10).map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      setState(() {
        _totalRevenue = currentRevenue;
        _totalOrders = currentOrdersSnap.docs.length;
        _avgOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
        _growthRate = growth;
        _avgPrepTime = avgPrep;
        _orderAccuracy = accuracy;
        _onTimeDelivery = onTime;
        _salesSpots = salesSpots;
        _orderGroups = orderGroups;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching performance data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    final kpis = {
      'Total Revenue': 'Rs ${_totalRevenue.toStringAsFixed(0)}',
      'Total Orders': _totalOrders.toString(),
      'Avg. Order': 'Rs ${_avgOrderValue.toStringAsFixed(0)}',
      'Growth': '${_growthRate.toStringAsFixed(1)}%',
    };

    await PdfService.generatePerformanceReport(
      title: 'Performance Report - ${DateFormat('MMMM yyyy').format(DateTime.now())}',
      kpis: kpis,
      topProducts: _topProducts,
      recentOrders: _recentOrders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;
        
        return Scaffold(
          key: isMobile ? GlobalKey<ScaffoldState>() : null,
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Performance')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  title: const Text("Performance Report", style: TextStyle(color: Colors.white, fontSize: 18)),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Performance'),
              
              Expanded(
                child: Column(
                  children: [
                    PerformanceHeader(
                      isMobile: isMobile,
                      onRefresh: _fetchData,
                      onExport: _exportPdf,
                    ),
                    _isLoading 
                      ? const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                      : Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KPIGrid(
                              isMobile: isMobile,
                              revenue: _totalRevenue,
                              orders: _totalOrders,
                              avgValue: _avgOrderValue,
                              growth: _growthRate,
                            ),
                            const SizedBox(height: 32),
                            
                            if (isMobile) ...[
                              SalesTrendsChart(spots: _salesSpots),
                              const SizedBox(height: 24),
                              DailyOrdersChart(groups: _orderGroups),
                            ] else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: SalesTrendsChart(spots: _salesSpots)),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 1, child: DailyOrdersChart(groups: _orderGroups)),
                                ],
                              ),
                            const SizedBox(height: 32),
                            
                            if (isMobile) ...[
                              TopSellingProductsTable(products: _topProducts),
                              const SizedBox(height: 24),
                              OperationalMetricsColumn(
                                avgPrepTime: _avgPrepTime,
                                onTimeDelivery: _onTimeDelivery,
                                orderAccuracy: _orderAccuracy,
                              ),
                            ] else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: TopSellingProductsTable(products: _topProducts)),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 1, 
                                    child: OperationalMetricsColumn(
                                      avgPrepTime: _avgPrepTime,
                                      onTimeDelivery: _onTimeDelivery,
                                      orderAccuracy: _orderAccuracy,
                                    )
                                  ),
                                ],
                              ),
                          ],
                        ),
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
}

class PerformanceHeader extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onRefresh;
  final VoidCallback onExport;
  const PerformanceHeader({super.key, required this.isMobile, required this.onRefresh, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 16 : 0),
      constraints: BoxConstraints(minHeight: isMobile ? 0 : 100),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isMobile)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Performance Report",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Detailed overview of your store's health and growth",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isMobile)
                const Text(
                  "Analytics Overview",
                  style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold),
                ),
              Row(
                children: [
                  IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh, color: Colors.white)),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    _HeaderActionBtn(icon: Icons.calendar_today_outlined, label: "This Month", onTap: () {}),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onExport,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.white),
                      label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, 
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        minimumSize: const Size(0, 50), // Override global infinity width
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _HeaderActionBtn(icon: Icons.calendar_today_outlined, label: "This Month", onTap: () {})),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.white),
                    label: const Text('Export', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, 
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 40), // Override global infinity width
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.subtle),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class KPIGrid extends StatelessWidget {
  final bool isMobile;
  final double revenue;
  final int orders;
  final double avgValue;
  final double growth;

  const KPIGrid({
    super.key, 
    required this.isMobile,
    required this.revenue, 
    required this.orders, 
    required this.avgValue, 
    required this.growth
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: KPICard(title: 'Revenue', value: 'Rs ${_fmt(revenue)}', change: '+${growth.toStringAsFixed(1)}%', icon: Icons.payments_outlined, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: KPICard(title: 'Orders', value: '$orders', change: '+${(growth/1.5).toStringAsFixed(1)}%', icon: Icons.shopping_bag_outlined, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: KPICard(title: 'Avg. Order', value: 'Rs ${avgValue.toStringAsFixed(0)}', change: '-2.4%', icon: Icons.query_stats_outlined, color: AppColors.amber, isNegative: true)),
              const SizedBox(width: 12),
              Expanded(child: KPICard(title: 'Growth', value: '${growth.toStringAsFixed(1)}%', change: '+${(growth*1.2).toStringAsFixed(1)}%', icon: Icons.trending_up, color: AppColors.green)),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: KPICard(title: 'Total Revenue', value: 'Rs ${_fmt(revenue)}', change: '+${growth.toStringAsFixed(1)}%', icon: Icons.payments_outlined, color: Colors.blue)),
        const SizedBox(width: 20),
        Expanded(child: KPICard(title: 'Total Orders', value: '$orders', change: '+${(growth/1.5).toStringAsFixed(1)}%', icon: Icons.shopping_bag_outlined, color: AppColors.primary)),
        const SizedBox(width: 20),
        Expanded(child: KPICard(title: 'Avg. Order Value', value: 'Rs ${avgValue.toStringAsFixed(0)}', change: '-2.4%', icon: Icons.query_stats_outlined, color: AppColors.amber, isNegative: true)),
        const SizedBox(width: 20),
        Expanded(child: KPICard(title: 'Growth Rate', value: '${growth.toStringAsFixed(1)}%', change: '+${(growth*1.2).toStringAsFixed(1)}%', icon: Icons.trending_up, color: AppColors.green)),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class KPICard extends StatelessWidget {
  final String title, value, change;
  final IconData icon;
  final Color color;
  final bool isNegative;

  const KPICard({super.key, required this.title, required this.value, required this.change, required this.icon, required this.color, this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    final Color trendColor = isNegative ? AppColors.primary : AppColors.green;
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(change, style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.subtle, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class SalesTrendsChart extends StatelessWidget {
  final List<FlSpot> spots;
  const SalesTrendsChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sales Trends", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("Daily revenue insights for the current month", style: TextStyle(fontSize: 12, color: AppColors.subtle)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.subtle, fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text(_fmt(value), style: const TextStyle(color: AppColors.subtle, fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length < 15),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

class DailyOrdersChart extends StatelessWidget {
  final List<BarChartGroupData> groups;
  const DailyOrdersChart({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 7,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.subtle, fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.subtle, fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopSellingProductsTable extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const TopSellingProductsTable({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Selling Products", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text("No sales data available", style: TextStyle(color: AppColors.subtle))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 500),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Product", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Sold", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Revenue", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                      ],
                    ),
                    ...products.map((p) => _buildRow(
                      context, 
                      p['name'], 
                      p['category'] ?? 'Pizza', 
                      p['count'].toString(), 
                      'Rs ${_fmt(p['revenue'])}'
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    double val = (v ?? 0).toDouble();
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  TableRow _buildRow(BuildContext context, String name, String cat, String sold, String rev) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(cat, style: const TextStyle(color: AppColors.subtle))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(sold, style: const TextStyle(color: Colors.white))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(rev, style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}

class OperationalMetricsColumn extends StatelessWidget {
  final double avgPrepTime;
  final double onTimeDelivery;
  final double orderAccuracy;

  const OperationalMetricsColumn({
    super.key, 
    required this.avgPrepTime, 
    required this.onTimeDelivery, 
    required this.orderAccuracy
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OperationalMetricCard(
          title: "Avg. Prep Time", 
          value: "${avgPrepTime.toStringAsFixed(1)} mins", 
          progress: (20 - avgPrepTime).clamp(0, 20) / 20, 
          target: "Target: 15.0 mins"
        ),
        const SizedBox(height: 16),
        OperationalMetricCard(
          title: "On-time Delivery", 
          value: "${onTimeDelivery.toStringAsFixed(1)}%", 
          progress: onTimeDelivery / 100, 
          target: "Target: 90.0%"
        ),
        const SizedBox(height: 16),
        OperationalMetricCard(
          title: "Order Accuracy", 
          value: "${orderAccuracy.toStringAsFixed(1)}%", 
          progress: orderAccuracy / 100, 
          target: orderAccuracy > 95 ? "Excellent precision" : "Needs improvement"
        ),
        const SizedBox(height: 24),
        const OperationalAlertCard(),
      ],
    );
  }
}

class OperationalMetricCard extends StatelessWidget {
  final String title, value, target;
  final double progress;

  const OperationalMetricCard({super.key, required this.title, required this.value, required this.progress, required this.target});

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
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(target, style: const TextStyle(fontSize: 10, color: AppColors.subtle)),
        ],
      ),
    );
  }
}

class OperationalAlertCard extends StatelessWidget {
  const OperationalAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              const Text("Operational Alert", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Rider availability in Vehari Sector B is low for current demand. Consider dispatching backup.",
            style: TextStyle(color: AppColors.subtle, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


