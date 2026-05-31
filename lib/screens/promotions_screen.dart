import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/firestore_service.dart';

class PromotionsManagementScreen extends StatefulWidget {
  const PromotionsManagementScreen({super.key});

  @override
  State<PromotionsManagementScreen> createState() => _PromotionsManagementScreenState();
}

class _PromotionsManagementScreenState extends State<PromotionsManagementScreen> {
  void _showPromoDialog([Map<String, dynamic>? promo]) {
    final bool isEditing = promo != null;
    final TextEditingController titleController = TextEditingController(text: promo?[FirestoreConstants.title]);
    final TextEditingController codeController = TextEditingController(text: promo?[FirestoreConstants.code]);
    final TextEditingController descController = TextEditingController(text: promo?[FirestoreConstants.description]);
    String status = promo?[FirestoreConstants.status] ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(isEditing ? 'Edit Promotion' : 'Create New Promotion', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Promo Code', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppColors.subtle)),
                  items: ['Active', 'Paused', 'Expired'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => status = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  FirestoreConstants.title: titleController.text,
                  FirestoreConstants.code: codeController.text,
                  FirestoreConstants.description: descController.text,
                  FirestoreConstants.status: status,
                };
                if (isEditing) {
                  await FirestoreService().updatePromotion(promo[FirestoreConstants.id], data);
                } else {
                  await FirestoreService().addPromotion(data);
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
              ),
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1000;
        
        return Scaffold(
          key: isMobile ? GlobalKey<ScaffoldState>() : null,
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Promotions')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  title: const Text("Marketing & Promotions", style: TextStyle(color: Colors.white, fontSize: 18)),
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
              // Sidebar
              if (!isMobile) const AdminSidebar(activeItem: 'Promotions'),
              
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    PromotionsHeader(isMobile: isMobile),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: FirestoreService().getPromotions(adminId: FirebaseAuth.instance.currentUser?.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final promotions = snapshot.data ?? [];

                          return SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Promotions Grid
                                PromotionsGrid(
                                  isMobile: isMobile,
                                  promotions: promotions,
                                  onEdit: (promo) => _showPromoDialog(promo),
                                ),
                                const SizedBox(height: 32),
                                
                                // Performance Stats Section
                                const SectionHeader(title: "Recent Campaign Performance"),
                                const SizedBox(height: 16),
                                CampaignStatsTable(isMobile: isMobile),
                              ],
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// Removed redundant local AdminSidebar and SidebarItem classes to use the centralized shared component.

// ================= Header =================
class PromotionsHeader extends StatelessWidget {
  final bool isMobile;
  const PromotionsHeader({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 12 : 0),
      constraints: BoxConstraints(minHeight: isMobile ? 0 : 100),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isMobile)
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Marketing & Promotions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text("Create and manage discount offers and campaigns.", style: TextStyle(fontSize: 14, color: AppColors.subtle)),
              ],
            ),
          if (!isMobile) const Spacer(),
          Expanded(
            flex: isMobile ? 1 : 0,
            child: ElevatedButton.icon(
              onPressed: () {
                final state = context.findAncestorStateOfType<_PromotionsManagementScreenState>();
                state?._showPromoDialog();
              },
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(isMobile ? 'New Offer' : 'Create New Offer', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                minimumSize: const Size(0, 50), // Override global infinity width
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Promotions Grid =================
class PromotionsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> promotions;
  final Function(Map<String, dynamic>) onEdit;
  final bool isMobile;
  const PromotionsGrid({super.key, required this.promotions, required this.onEdit, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Active Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton(onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viewing all offers...')));
            }, child: const Text("View All", style: TextStyle(color: AppColors.primary))),
          ],
        ),
        const SizedBox(height: 16),
        promotions.isEmpty 
        ? Container(
            padding: const EdgeInsets.all(40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text("No active promotions found.", style: TextStyle(color: AppColors.subtle))),
          )
        : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: promotions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isMobile ? 2.5 : 2.2,
          ),
          itemBuilder: (context, index) {
            final promo = promotions[index];
            return PromoCard(
              title: promo[FirestoreConstants.title] ?? 'Special Offer',
              code: promo[FirestoreConstants.code] ?? 'N/A',
              desc: promo[FirestoreConstants.description] ?? 'Limited time offer.',
              status: promo[FirestoreConstants.status] ?? 'Active',
              color: _getStatusColor(promo[FirestoreConstants.status]),
              onEdit: () => onEdit(promo),
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('Delete Promotion', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to delete this promotion?', style: TextStyle(color: AppColors.subtle)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirestoreService().deletePromotion(promo[FirestoreConstants.id]);
                }
              },
            );
          },
        )
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return AppColors.green;
      case 'paused': return AppColors.subtle;
      case 'expired': return AppColors.primary;
      default: return AppColors.primary;
    }
  }
}

class PromoCard extends StatelessWidget {
  final String title, code, desc, status;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PromoCard({super.key, required this.title, required this.code, required this.desc, required this.status, required this.color, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Text("CODE: $code", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), color: AppColors.subtle),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline), color: AppColors.primary.withValues(alpha: 0.7)),
            ],
          )
        ],
      ),
    );
  }
}

// ================= Table =================
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }
}

class CampaignStatsTable extends StatelessWidget {
  final bool isMobile;
  const CampaignStatsTable({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text("Campaign Insights", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (!isMobile)
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changing sort order...')));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text("Sorted by: Revenue", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ),
              ],
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getPromotionPerformance(adminId: FirebaseAuth.instance.currentUser?.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final campaigns = snapshot.data ?? [];

              if (campaigns.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text("No campaign data available.", style: TextStyle(color: AppColors.subtle))),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: AppColors.border,
                  ),
                  child: DataTable(
                    horizontalMargin: 24,
                    columns: const [
                      DataColumn(label: Text("Campaign", style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Redemptions", style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Revenue Generated", style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("New Customers", style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("ROI", style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.bold))),
                    ],
                    rows: campaigns.map((campaign) => _buildRow(
                      context, 
                      campaign[FirestoreConstants.title] ?? 'N/A', 
                      campaign[FirestoreConstants.redemptions].toString(), 
                      "Rs. ${campaign[FirestoreConstants.revenueGenerated]}", 
                      campaign[FirestoreConstants.newCustomers].toString(), 
                      campaign[FirestoreConstants.roi].toString()
                    )).toList(),
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, String name, String red, String rev, String customers, String roi) {
    return DataRow(cells: [
      DataCell(InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing analytics for $name')));
        },
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      )),
      DataCell(Text(red, style: const TextStyle(color: Colors.white))),
      DataCell(Text(rev, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
      DataCell(Text(customers, style: const TextStyle(color: Colors.white))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(roi, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
      )),
    ]);
  }
}


