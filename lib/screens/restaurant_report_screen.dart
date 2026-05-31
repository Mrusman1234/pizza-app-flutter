import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';

class RestaurantReportScreen extends StatefulWidget {
  const RestaurantReportScreen({super.key});

  @override
  State<RestaurantReportScreen> createState() => _RestaurantReportScreenState();
}

class _RestaurantReportScreenState extends State<RestaurantReportScreen> {
  String? selectedRestaurantId;
  String? selectedRestaurantName;
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  // Stats
  double totalRevenue = 0;
  int totalOrders = 0;
  double avgOrderValue = 0;
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> topItems = [];

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(FirestoreConstants.restaurants).get();
      if (!mounted) return;
      
      final list = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()[FirestoreConstants.name] ?? 'Unknown',
      }).toList();

      setState(() {
        restaurants = list;
        if (list.isNotEmpty) {
          selectedRestaurantId = list[0]['id'];
          selectedRestaurantName = list[0]['name'];
          _fetchReportData();
        } else {
          isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchReportData() async {
    if (selectedRestaurantId == null) return;
    setState(() => isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection(FirestoreConstants.orders);
      
      // Attempt to filter by restaurantId if it's not a "global" view
      if (selectedRestaurantId != null) {
        query = query.where(FirestoreConstants.restaurantId, isEqualTo: selectedRestaurantId);
      }
      
      final ordersSnapshot = await query.get();
      if (!mounted) return;

      // If no orders found for specific restaurant, and we are in demo mode, 
      // maybe fetch all and filter in memory if some fields are missing in DB
      List<DocumentSnapshot> finalDocs = ordersSnapshot.docs;
      
      if (finalDocs.isEmpty && selectedRestaurantId != null) {
        final allOrders = await FirebaseFirestore.instance.collection(FirestoreConstants.orders).limit(50).get();
        if (!mounted) return;
        
        finalDocs = allOrders.docs.where((doc) {
          final data = doc.data();
          return data[FirestoreConstants.restaurantId] == selectedRestaurantId;
        }).toList();
      }

      double revenue = 0;
      final List<Map<String, dynamic>> orders = [];
      final Map<String, int> itemCounts = {};
      final Map<String, double> itemRevenue = {};

      for (var doc in finalDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data[FirestoreConstants.totalAmount] ?? 0).toDouble();
        revenue += amount;
        
        orders.add({
          'id': doc.id.substring(0, 6).toUpperCase(),
          'customer': data[FirestoreConstants.userName] ?? 'Guest',
          'amount': amount,
          'status': data[FirestoreConstants.status] ?? FirestoreConstants.statusPending,
        });

        final items = data[FirestoreConstants.items] as List? ?? [];
        for (var item in items) {
          final name = item['name'] ?? 'Unknown';
          final qty = (item['quantity'] ?? 0) as int;
          final price = (item['price'] ?? 0).toDouble();
          itemCounts[name] = (itemCounts[name] ?? 0) + qty;
          itemRevenue[name] = (itemRevenue[name] ?? 0) + (price * qty);
        }
      }

      final List<Map<String, dynamic>> sortedItems = itemCounts.entries.map((e) => {
        'name': e.key,
        'sold': e.value,
        'revenue': itemRevenue[e.key] ?? 0,
      }).toList();
      sortedItems.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));

      setState(() {
        totalRevenue = revenue;
        totalOrders = ordersSnapshot.docs.length;
        avgOrderValue = totalOrders > 0 ? revenue / totalOrders : 0;
        recentOrders = orders.take(5).toList();
        topItems = sortedItems.take(4).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching report: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Restaurant Performance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Restaurant: $selectedRestaurantName', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [pw.Text('Total Revenue'), pw.Text('Rs. ${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
                  pw.Column(children: [pw.Text('Total Orders'), pw.Text('$totalOrders', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
                  pw.Column(children: [pw.Text('Avg. Order'), pw.Text('Rs. ${avgOrderValue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('Top Selling Items', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Item Name', 'Quantity Sold', 'Revenue'],
                data: topItems.map((item) => [item['name'], item['sold'].toString(), 'Rs. ${item['revenue'].toStringAsFixed(0)}']).toList(),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Recent Orders', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Order ID', 'Customer', 'Amount', 'Status'],
                data: recentOrders.map((o) => [o['id'], o['customer'], 'Rs. ${o['amount']}', o['status']]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          key: isMobile ? GlobalKey<ScaffoldState>() : null,
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Store Report')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  title: const Text("Restaurant Reports", style: TextStyle(color: Colors.white, fontSize: 18)),
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
              if (!isMobile) const AdminSidebar(activeItem: 'Store Report'),
              Expanded(
                child: Column(
                  children: [
                    ReportHeader(
                      isMobile: isMobile,
                      restaurants: restaurants,
                      selectedId: selectedRestaurantId,
                      onChanged: (id) {
                        setState(() {
                          selectedRestaurantId = id;
                          selectedRestaurantName = restaurants.firstWhere((r) => r['id'] == id)['name'];
                        });
                        _fetchReportData();
                      },
                      onExport: _exportPdf,
                    ),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  MetricCardsGrid(
                                    isMobile: isMobile,
                                    revenue: totalRevenue,
                                    orders: totalOrders,
                                    avgOrder: avgOrderValue,
                                  ),
                                  const SizedBox(height: 24),
                                  const SalesTrendChart(),
                                  const SizedBox(height: 24),
                                  if (isMobile) ...[
                                    TopSellingItems(items: topItems),
                                    const SizedBox(height: 24),
                                    const OperationalEfficiency(),
                                  ] else
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 2, child: TopSellingItems(items: topItems)),
                                        const SizedBox(width: 24),
                                        const Expanded(flex: 1, child: OperationalEfficiency()),
                                      ],
                                    ),
                                  const SizedBox(height: 24),
                                  if (isMobile) ...[
                                    const CustomerFeedback(),
                                    const SizedBox(height: 24),
                                    RecentOrdersTable(orders: recentOrders),
                                  ] else
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(child: CustomerFeedback()),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 2, child: RecentOrdersTable(orders: recentOrders)),
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

// Removed redundant local AdminSidebar and SidebarItem classes to use the centralized shared component.

// ================= Header =================
class ReportHeader extends StatelessWidget {
  final bool isMobile;
  final List<Map<String, dynamic>> restaurants;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onExport;

  const ReportHeader({
    super.key,
    required this.isMobile,
    required this.restaurants,
    required this.selectedId,
    required this.onChanged,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedId,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        items: restaurants.map((r) {
                          return DropdownMenuItem<String>(
                            value: r['id'],
                            child: Text(
                              r['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: onChanged,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Performance Overview • Store Analytics",
                      style: TextStyle(fontSize: isMobile ? 12 : 14, color: AppColors.subtle),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                  label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================= Metric Cards =================
class MetricCardsGrid extends StatelessWidget {
  final bool isMobile;
  final double revenue;
  final int orders;
  final double avgOrder;

  const MetricCardsGrid({
    super.key,
    required this.isMobile,
    required this.revenue,
    required this.orders,
    required this.avgOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: MetricCard(title: 'Revenue', value: 'Rs. ${revenue.toStringAsFixed(0)}', percent: 'Live', isPositive: true)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(title: 'Orders', value: '$orders', percent: 'Orders', isPositive: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: MetricCard(title: 'Avg. Order', value: 'Rs. ${avgOrder.toStringAsFixed(0)}', percent: 'Avg', isPositive: true)),
              const SizedBox(width: 12),
              const Expanded(child: MetricCard(title: 'Growth %', value: '+0.0%', percent: '0%', isPositive: true)),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: MetricCard(title: 'Total Revenue', value: 'Rs. ${revenue.toStringAsFixed(0)}', percent: 'Live', isPositive: true)),
        const SizedBox(width: 16),
        Expanded(child: MetricCard(title: 'Total Orders', value: '$orders', percent: 'Orders', isPositive: true)),
        const SizedBox(width: 16),
        Expanded(child: MetricCard(title: 'Avg. Order Value', value: 'Rs. ${avgOrder.toStringAsFixed(0)}', percent: 'Avg', isPositive: true)),
        const SizedBox(width: 16),
        const Expanded(child: MetricCard(title: 'Growth %', value: '+0.0%', percent: '0%', isPositive: true)),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title, value, percent;
  final bool isPositive;

  const MetricCard({super.key, required this.title, required this.value, required this.percent, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final Color trendColor = isPositive ? AppColors.green : AppColors.primary;
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
          Text(title, style: const TextStyle(color: AppColors.subtle, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 14, color: trendColor),
                    const SizedBox(width: 4),
                    Text(percent, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// ================= Sales Trend Chart =================
class SalesTrendChart extends StatefulWidget {
  const SalesTrendChart({super.key});

  @override
  State<SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<SalesTrendChart> {
  bool isDaily = true;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Daily Sales Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  _buildToggleBtn("Daily", isDaily, () => setState(() => isDaily = true)),
                  const SizedBox(width: 8),
                  _buildToggleBtn("Weekly", !isDaily, () => setState(() => isDaily = false)),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.subtle, fontSize: 12)))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: AppColors.subtle, fontSize: 12);
                        switch (value.toInt()) {
                          case 0: return const Text('Oct 01', style: style);
                          case 2: return const Text('Oct 07', style: style);
                          case 4: return const Text('Oct 14', style: style);
                          case 6: return const Text('Oct 21', style: style);
                          case 8: return const Text('Oct 31', style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(2, 4), FlSpot(4, 3.5), FlSpot(6, 5), FlSpot(8, 4.5)],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.subtle, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ================= Top Selling Items =================
class TopSellingItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const TopSellingItems({super.key, required this.items});

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
          const Text("Top Selling Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No items sold yet", style: TextStyle(color: AppColors.subtle))))
          else
            ...items.map((item) => _buildItemRow(context, item['name'], "${item['sold']} sold", "Rs. ${item['revenue'].toStringAsFixed(0)}")),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, String name, String sold, String revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_pizza, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(sold, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
              ],
            ),
          ),
          Text(revenue, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ================= Operational Efficiency =================
class OperationalEfficiency extends StatelessWidget {
  const OperationalEfficiency({super.key});

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
          const Text("Operational Efficiency", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          _buildEffRow(context, "Avg. Prep Time", "12 min", 0.85, AppColors.green),
          _buildEffRow(context, "On-time Delivery", "94%", 0.94, Colors.blue),
          _buildEffRow(context, "Order Accuracy", "98%", 0.98, AppColors.amber),
        ],
      ),
    );
  }

  Widget _buildEffRow(BuildContext context, String label, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.background, color: color),
          )
        ],
      ),
    );
  }
}

// ================= Customer Feedback =================
class CustomerFeedback extends StatelessWidget {
  const CustomerFeedback({super.key});

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
          const Text("Recent Customer Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          _buildFeedbackItem(context, "Ali R.", "5.0", "Best pizza in Vehari! Fast service."),
          _buildFeedbackItem(context, "Zainab B.", "4.0", "Very cheesy and hot. Loved it."),
          _buildFeedbackItem(context, "Usman K.", "4.5", "Great toppings, crust was perfect."),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(BuildContext context, String user, String rating, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(user, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Row(children: [const Icon(Icons.star, color: AppColors.amber, size: 14), Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))]),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
        ],
      ),
    );
  }
}

// ================= Recent Orders Table =================
class RecentOrdersTable extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const RecentOrdersTable({super.key, required this.orders});

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Recent Performance History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (orders.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No recent orders", style: TextStyle(color: AppColors.subtle))))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Order ID", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle))),
                      ],
                    ),
                    ...orders.map((o) => _buildRow(context, "#${o['id']}", o['customer'], "Rs. ${o['amount']}", o['status'], _getStatusColor(o['status']))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == FirestoreConstants.statusDelivered) return AppColors.green;
    if (status == FirestoreConstants.statusCancelled) return AppColors.primary;
    return AppColors.amber;
  }

  TableRow _buildRow(BuildContext context, String id, String user, String amount, String status, Color color) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(user, style: const TextStyle(color: Colors.white))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(amount, style: const TextStyle(color: Colors.white))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}


