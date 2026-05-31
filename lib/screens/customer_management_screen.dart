import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../routes/route_names.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _filtered = [];

  String _filterStatus = 'All'; // All | Active | Blocked
  String _sortBy = 'Newest';    // Newest | Most Orders | Top Spender

  bool _isLoading = true;

  int _totalCustomers = 0;
  int _activeCustomers = 0;
  int _blockedCustomers = 0;
  int _newThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final String? adminId = FirebaseAuth.instance.currentUser?.uid;
      
      // Load customers
      final usersSnap = await _db
          .collection(FirestoreConstants.users)
          .where(FirestoreConstants.role, isEqualTo: FirestoreConstants.roleCustomer)
          .get();

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final List<CustomerModel> list = [];

      for (final doc in usersSnap.docs) {
        final data = doc.data();

        // Get orders for this customer that belong to this admin's restaurants
        Query ordersQuery = _db.collection(FirestoreConstants.orders).where(FirestoreConstants.userId, isEqualTo: doc.id);
        if (adminId != null) {
          ordersQuery = ordersQuery.where(FirestoreConstants.adminId, isEqualTo: adminId);
        }
        
        final ordersSnap = await ordersQuery.get();

        double totalSpent = 0;
        int orderCount = 0;
        DateTime? lastOrderDate;

        for (final o in ordersSnap.docs) {
          final oData = o.data() as Map<String, dynamic>;
          if ((oData[FirestoreConstants.status] ?? '') == FirestoreConstants.statusDelivered) {
            totalSpent += (oData[FirestoreConstants.totalAmount] ?? 0).toDouble();
            orderCount++;
            final ts = oData[FirestoreConstants.createdAt] as Timestamp?;
            if (ts != null) {
              final dt = ts.toDate();
              if (lastOrderDate == null || dt.isAfter(lastOrderDate)) {
                lastOrderDate = dt;
              }
            }
          }
        }

        final createdAt = (data[FirestoreConstants.createdAt] as Timestamp?)?.toDate();

        list.add(CustomerModel(
          id: doc.id,
          name: data[FirestoreConstants.name] ?? data[FirestoreConstants.displayName] ?? 'Unknown',
          email: data[FirestoreConstants.email] ?? '',
          phone: data[FirestoreConstants.phone] ?? data[FirestoreConstants.phoneNumber] ?? '',
          photoUrl: data[FirestoreConstants.photoUrl] ?? data[FirestoreConstants.profileImage] ?? '',
          isBlocked: data[FirestoreConstants.isBlocked] == true,
          totalOrders: orderCount,
          totalSpent: totalSpent,
          lastOrderDate: lastOrderDate,
          createdAt: createdAt,
        ));
      }

      int active = 0, blocked = 0, newMonth = 0;
      for (final c in list) {
        if (c.isBlocked) {
          blocked++;
        } else {
          active++;
        }
        if (c.createdAt != null && c.createdAt!.isAfter(startOfMonth)) {
          newMonth++;
        }
      }

      setState(() {
        _allCustomers = list;
        _totalCustomers = list.length;
        _activeCustomers = active;
        _blockedCustomers = blocked;
        _newThisMonth = newMonth;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error loading customers: $e', isError: true);
    }
  }

  void _applyFilter() {
    var list = List<CustomerModel>.from(_allCustomers);
    final q = _searchController.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.phone.contains(q)
      ).toList();
    }
    if (_filterStatus == 'Active')  list = list.where((c) => !c.isBlocked).toList();
    if (_filterStatus == 'Blocked') list = list.where((c) => c.isBlocked).toList();
    switch (_sortBy) {
      case 'Most Orders':  list.sort((a, b) => b.totalOrders.compareTo(a.totalOrders)); break;
      case 'Top Spender':  list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent)); break;
      default:             list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    }
    setState(() => _filtered = list);
  }

  Future<void> _toggleBlock(CustomerModel customer) async {
    final willBlock = !customer.isBlocked;
    final confirmed = await _confirmDialog(
      title: willBlock ? 'Block customer?' : 'Unblock customer?',
      message: willBlock
          ? '${customer.name} will not be able to place orders or log in.'
          : '${customer.name} will regain full access to the app.',
      confirmLabel: willBlock ? 'Block' : 'Unblock',
      confirmColor: willBlock ? const Color(0xFFE03131) : const Color(0xFF2F9E44),
    );
    if (!confirmed) return;
    try {
      await _db.collection(FirestoreConstants.users).doc(customer.id).update({
        FirestoreConstants.isBlocked: willBlock,
        FirestoreConstants.blockedAt: willBlock ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
      _showSnack(willBlock ? '${customer.name} has been blocked' : '${customer.name} has been unblocked');
      _loadCustomers();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirmed = await _confirmDialog(
      title: 'Delete customer?',
      message: 'This permanently deletes ${customer.name}\'s account. This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: const Color(0xFFE03131),
    );
    if (!confirmed) return;
    try {
      await _db.collection(FirestoreConstants.users).doc(customer.id).delete();
      _showSnack('${customer.name} deleted');
      _loadCustomers();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  void _viewCustomer(CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(customer: customer, db: _db),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF2F9E44),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        content: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.subtle))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          key: isMobile ? GlobalKey<ScaffoldState>() : null,
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Customers')) : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Customers'),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        backgroundColor: AppColors.card,
                        elevation: 0,
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        title: const Text("Customers", style: TextStyle(color: Colors.white, fontSize: 18)),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _loadCustomers,
                          ),
                        ],
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  if (!isMobile) ...[
                                    _buildHeader(),
                                    const SizedBox(height: 32),
                                  ],
                                  // Stats Cards
                                  _buildStats(),
                                  const SizedBox(height: 32),
                                  // Search & Filters
                                  _buildFilters(),
                                  const SizedBox(height: 24),
                                  // Customer Table
                                  _buildCustomerTable(),
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

  Widget _buildHeader() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Customer Management",
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 4),
                Text(
                  "Manage and monitor your customer base and their lifetime value",
                  style: TextStyle(fontSize: 14, color: AppColors.subtle),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.subtle), 
            onPressed: _loadCustomers
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth < 600 ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              StatCard(icon: Icons.groups, title: "Total Customers", value: "$_totalCustomers", change: "TOTAL", color: Colors.blue),
              StatCard(icon: Icons.bolt, title: "Active", value: "$_activeCustomers", change: "LIVE", color: AppColors.green),
              StatCard(icon: Icons.block, title: "Blocked", value: "$_blockedCustomers", change: "RESTRICTED", color: AppColors.primary),
              StatCard(icon: Icons.person_add, title: "New This Month", value: "$_newThisMonth", change: "NEW", color: Colors.purple),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: StatCard(icon: Icons.groups, title: "Total Customers", value: "$_totalCustomers", change: "TOTAL", color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(icon: Icons.bolt, title: "Active", value: "$_activeCustomers", change: "LIVE", color: AppColors.green)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(icon: Icons.block, title: "Blocked", value: "$_blockedCustomers", change: "RESTRICTED", color: AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(icon: Icons.person_add, title: "New This Month", value: "$_newThisMonth", change: "NEW", color: Colors.purple)),
            ],
          );
        }
      },
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 750) {
          return Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.subtle),
                  hintText: "Search customers...",
                  hintStyle: const TextStyle(color: AppColors.subtle, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: ['All', 'Active', 'Blocked'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) { if (v != null) { setState(() => _filterStatus = v); _applyFilter(); } },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: ['Newest', 'Most Orders', 'Top Spender'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) { if (v != null) { setState(() => _sortBy = v); _applyFilter(); } },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppColors.subtle),
                    hintText: "Search customers by name, email or phone...",
                    hintStyle: const TextStyle(color: AppColors.subtle),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
                    items: ['All', 'Active', 'Blocked'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) { if (v != null) { setState(() => _filterStatus = v); _applyFilter(); } },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
                    items: ['Newest', 'Most Orders', 'Top Spender'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) { if (v != null) { setState(() => _sortBy = v); _applyFilter(); } },
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCustomerTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: _filtered.isEmpty
          ? SizedBox(height: 300, child: _buildEmptyState())
          : Theme(
              data: Theme.of(context).copyWith(
                cardColor: AppColors.card,
                dividerColor: AppColors.border,
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 900),
                    child: DataTable(
                      headingTextStyle: const TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold),
                      dataTextStyle: const TextStyle(color: Colors.white),
                      columns: const [
                        DataColumn(label: Text("Customer")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Joined")),
                        DataColumn(label: Text("Orders"), numeric: true),
                        DataColumn(label: Text("Total Spent")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: _filtered.map((customer) {
                        return DataRow(
                          cells: [
                            DataCell(Row(
                              children: [
                                _Avatar(name: customer.name, photoUrl: customer.photoUrl, isBlocked: customer.isBlocked, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                    Text(customer.id.substring(0, 8), style: const TextStyle(color: AppColors.subtle, fontSize: 10)),
                                  ],
                                ),
                              ],
                            )),
                            DataCell(Text(customer.email, style: const TextStyle(fontSize: 13))),
                            DataCell(Text(customer.createdAt != null ? "${customer.createdAt!.day}/${customer.createdAt!.month}/${customer.createdAt!.year}" : "N/A", style: const TextStyle(fontSize: 13))),
                            DataCell(Text(customer.totalOrders.toString())),
                            DataCell(Text("Rs ${customer.totalSpent.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green, fontSize: 13))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: !customer.isBlocked ? AppColors.green.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                customer.isBlocked ? 'Blocked' : 'Active',
                                style: TextStyle(
                                    color: !customer.isBlocked ? AppColors.green : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                            )),
                            DataCell(Row(
                              children: [
                                IconButton(onPressed: () => _viewCustomer(customer), icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.subtle)),
                                IconButton(onPressed: () => _toggleBlock(customer), icon: Icon(customer.isBlocked ? Icons.lock_open_outlined : Icons.block_outlined, color: customer.isBlocked ? AppColors.green : AppColors.amber, size: 18)),
                                IconButton(onPressed: () => _deleteCustomer(customer), icon: const Icon(Icons.delete_outline, color: AppColors.primary, size: 18)),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 56, color: AppColors.border),
        const SizedBox(height: 12),
        Text(
          _searchController.text.isNotEmpty ? 'No customers match your search' : 'No customers found',
          style: const TextStyle(color: AppColors.subtle, fontSize: 14),
        ),
      ],
    ),
  );
}

// Removed local SidebarItem class to use shared AdminSidebar component.


class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String change;
  final Color color;

  const StatCard({super.key, required this.icon, required this.title, required this.value, required this.change, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
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
              Flexible(
                child: Text(
                  change, 
                  style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title, 
            style: const TextStyle(color: AppColors.subtle, fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  final CustomerModel customer;
  final FirebaseFirestore db;
  const _CustomerDetailSheet({required this.customer, required this.db});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Row(children: [
            _Avatar(name: customer.name, photoUrl: customer.photoUrl, isBlocked: customer.isBlocked, size: 60),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              if (customer.email.isNotEmpty) Text(customer.email, style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
              if (customer.phone.isNotEmpty) Text(customer.phone, style: const TextStyle(fontSize: 14, color: AppColors.subtle)),
            ])),
          ]),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 24),
          Row(children: [
            _DetailStat(label: 'Total Orders', value: '${customer.totalOrders}'),
            _DetailStat(label: 'Total Spent', value: 'Rs ${customer.totalSpent.toStringAsFixed(0)}'),
            _DetailStat(label: 'Member Since', value: customer.createdAt != null ? '${_monthName(customer.createdAt!.month)} ${customer.createdAt!.year}' : 'N/A'),
          ]),
          const SizedBox(height: 32),
          const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection(FirestoreConstants.orders)
                .where(FirestoreConstants.userId, isEqualTo: customer.id)
                .where(FirestoreConstants.adminId, isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .orderBy(FirestoreConstants.createdAt, descending: true)
                .limit(5)
                .snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) return Center(child: Text('Error loading history: ${snap.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No order history available.', style: TextStyle(color: AppColors.subtle, fontSize: 13)));
                return ListView(
                  children: snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = (d[FirestoreConstants.status] ?? FirestoreConstants.statusPending).toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.pushNamed(context, RouteNames.orderDetails, arguments: doc.id),
                        title: Text('Order #${doc.id.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Rs ${(d[FirestoreConstants.totalAmount] ?? 0).toStringAsFixed(0)}', style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }

  Color _statusColor(String status) {
    if (status == FirestoreConstants.statusDelivered) return AppColors.green;
    if (status == FirestoreConstants.statusPending) return AppColors.amber;
    if (status == FirestoreConstants.statusCancelled) return AppColors.primary;
    return AppColors.subtle;
  }
}

class _Avatar extends StatelessWidget {
  final String name, photoUrl;
  final bool isBlocked;
  final double size;
  const _Avatar({required this.name, required this.photoUrl, required this.isBlocked, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Stack(children: [
      CircleAvatar(
        radius: size / 2,
        backgroundColor: isBlocked ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.2),
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty ? Text(initials, style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: AppColors.primary)) : null,
      ),
      if (isBlocked) Positioned(
        right: 0, bottom: 0,
        child: Container(
          width: size * 0.35, height: size * 0.35,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.card, width: 2)),
          child: Icon(Icons.block, color: Colors.white, size: size * 0.2),
        ),
      ),
    ]);
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  const _DetailStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
    ]),
  );
}

class CustomerModel {
  final String id, name, email, phone, photoUrl;
  final bool isBlocked;
  final int totalOrders;
  final double totalSpent;
  final DateTime? lastOrderDate, createdAt;

  const CustomerModel({
    required this.id, required this.name, required this.email,
    required this.phone, required this.photoUrl, required this.isBlocked,
    required this.totalOrders, required this.totalSpent,
    this.lastOrderDate, this.createdAt,
  });
}


