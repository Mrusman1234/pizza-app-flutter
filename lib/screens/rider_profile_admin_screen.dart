import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';

class RiderProfileAdminScreen extends StatelessWidget {
  final Map<String, dynamic> rider;
  const RiderProfileAdminScreen({super.key, required this.rider});

  @override
  Widget build(BuildContext context) {
    final String name = rider[FirestoreConstants.name] ?? 'Unnamed Rider';
    final String riderIdDisplay = '#${rider[FirestoreConstants.id]?.toString().substring(0, 8) ?? 'N/A'}';
    final String status = rider[FirestoreConstants.status] ?? 'Active';
    final String email = rider[FirestoreConstants.email] ?? 'No Email';
    final String phone = rider[FirestoreConstants.phone] ?? rider[FirestoreConstants.phoneNumber] ?? '+92 000 0000000';
    final String zone = rider[FirestoreConstants.zone] ?? 'Downtown';
    final String avatar = rider[FirestoreConstants.image] ?? 'https://ui-avatars.com/api/?name=$name';
    final bool isActive = status == 'Active';
    final String joinedDate = rider[FirestoreConstants.createdAt] != null 
        ? (rider[FirestoreConstants.createdAt] as Timestamp).toDate().toString().split(' ')[0]
        : 'Recently';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 1000;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Riders')) : null,
          appBar: isMobile 
            ? AppBar(
                backgroundColor: AppColors.card,
                title: const Text("Rider Profile", style: TextStyle(color: Colors.white, fontSize: 18)),
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
              if (!isMobile) const AdminSidebar(activeItem: 'Riders'),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb & Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMobile) ...[
                                  const Text("Rider Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    const Text("Management", style: TextStyle(color: AppColors.subtle, fontSize: 14)),
                                    const Icon(Icons.chevron_right, size: 16, color: AppColors.subtle),
                                    const Text("Riders", style: TextStyle(color: AppColors.subtle, fontSize: 14)),
                                    const Icon(Icons.chevron_right, size: 16, color: AppColors.subtle),
                                    Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile) ...[
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: AppColors.subtle),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.card,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Profile Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: EdgeInsets.all(isMobile ? 20 : 32),
                        child: Column(
                          children: [
                            if (isMobile) 
                              Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundImage: NetworkImage(avatar),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isActive ? AppColors.green : Colors.orange,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.card, width: 3),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: (isActive ? AppColors.green : Colors.orange).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(24)),
                                    child: Text(status.toUpperCase(),
                                        style: TextStyle(
                                            color: isActive ? AppColors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text("Rider ID: $riderIdDisplay",
                                      style: const TextStyle(color: AppColors.subtle, fontSize: 14)),
                                  Text("Joined $joinedDate",
                                      style: const TextStyle(color: AppColors.subtle, fontSize: 14)),
                                  const SizedBox(height: 24),
                                  _ContactInfo(icon: Icons.call_outlined, label: phone),
                                  const SizedBox(height: 12),
                                  _ContactInfo(icon: Icons.mail_outline, label: email),
                                  const SizedBox(height: 12),
                                  _ContactInfo(icon: Icons.location_on_outlined, label: zone),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 60,
                                        backgroundImage: NetworkImage(avatar),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isActive ? AppColors.green : Colors.orange,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.card, width: 4),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 32, color: Colors.white)),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                  color: (isActive ? AppColors.green : Colors.orange).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(24)),
                                              child: Text(status.toUpperCase(),
                                                  style: TextStyle(
                                                      color: isActive ? AppColors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text("Rider ID: $riderIdDisplay • Joined $joinedDate",
                                            style: const TextStyle(color: AppColors.subtle, fontSize: 14)),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(child: _ContactInfo(icon: Icons.call_outlined, label: phone)),
                                            const SizedBox(width: 32),
                                            Expanded(child: _ContactInfo(icon: Icons.mail_outline, label: email)),
                                            const SizedBox(width: 32),
                                            Expanded(child: _ContactInfo(icon: Icons.location_on_outlined, label: zone)),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            const SizedBox(height: 32),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 24),
                            if (isMobile)
                              Column(
                                children: [
                                  OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text("EDIT PROFILE"),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: AppColors.border),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                                      label: const Text("MESSAGE RIDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0)),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text("EDIT PROFILE"),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: AppColors.border),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                          minimumSize: const Size(0, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                                      label: const Text("MESSAGE RIDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                          minimumSize: const Size(0, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0)),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.block, color: AppColors.primary),
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  )
                                ],
                              )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Stats Row
                      if (isMobile)
                        Column(
                          children: [
                            Row(
                              children: [
                                _StatCard(Icons.delivery_dining_outlined, "Total Deliveries", "1,284", "+12%", Colors.blue),
                                const SizedBox(width: 12),
                                _StatCard(Icons.star_outline, "Average Rating", "4.8/5.0", "+0.2%", AppColors.amber),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatCard(Icons.payments_outlined, "Total Earnings", "Rs. 45,200", "+8%", AppColors.green),
                                const SizedBox(width: 12),
                                _StatCard(Icons.schedule_outlined, "On-time Rate", "98.5%", "-0.5%", Colors.purple),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            _StatCard(Icons.delivery_dining_outlined, "Total Deliveries", "1,284", "+12%", Colors.blue),
                            const SizedBox(width: 16),
                            _StatCard(Icons.star_outline, "Average Rating", "4.8/5.0", "+0.2%", AppColors.amber),
                            const SizedBox(width: 16),
                            _StatCard(Icons.payments_outlined, "Total Earnings", "Rs. 45,200", "+8%", AppColors.green),
                            const SizedBox(width: 16),
                            _StatCard(Icons.schedule_outlined, "On-time Rate", "98.5%", "-0.5%", Colors.purple),
                          ],
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Tables and Other Sections
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: isMobile ? 0 : 2,
                            child: Column(
                              children: [
                                // Recent Deliveries
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("Recent Deliveries", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                            TextButton(
                                              onPressed: () {},
                                              child: const Text("VIEW ALL", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1, color: AppColors.border),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minWidth: isMobile ? constraints.maxWidth - 32 : 0),
                                          child: DataTable(
                                            columnSpacing: 24,
                                            horizontalMargin: 24,
                                            headingRowColor: WidgetStateProperty.all(AppColors.background.withValues(alpha: 0.5)),
                                            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle, fontSize: 12),
                                            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
                                            columns: const [
                                              DataColumn(label: Text("ORDER ID")),
                                              DataColumn(label: Text("DATE")),
                                              DataColumn(label: Text("CUSTOMER")),
                                              DataColumn(label: Text("TIME")),
                                              DataColumn(label: Text("STATUS")),
                                            ],
                                            rows: [
                                              _buildDeliveryRow("#OPH-2041", "Oct 24, 2023", "Ali Ahmed", "22 mins", FirestoreConstants.statusDelivered),
                                              _buildDeliveryRow("#OPH-2040", "Oct 24, 2023", "Sara Khan", "18 mins", FirestoreConstants.statusDelivered),
                                              _buildDeliveryRow("#OPH-2039", "Oct 23, 2023", "Usman Ali", "25 mins", FirestoreConstants.statusDelivered),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Reviews
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  padding: EdgeInsets.all(isMobile ? 20 : 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Recent Reviews", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.star, color: AppColors.amber, size: 18),
                                                SizedBox(width: 6),
                                                Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      _buildReview("Asad Kamal", "2 hours ago", "Fast delivery and very polite rider. The pizza was still piping hot!", 5),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 24),
                                        child: Divider(color: AppColors.border),
                                      ),
                                      _buildReview("Farhan J.", "Yesterday", "Good service overall, just took a little longer than expected.", 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMobile) const SizedBox(height: 32) else const SizedBox(width: 32),
                          Flexible(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              children: [
                                // Documents
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  padding: EdgeInsets.all(isMobile ? 20 : 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Verification", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                      const SizedBox(height: 24),
                                      _buildDocumentItem(Icons.badge_outlined, "Driver's License", "Expires: 12/2025"),
                                      _buildDocumentItem(Icons.motorcycle_outlined, "Vehicle Reg.", "Honda 125 - ABC-1234"),
                                      _buildDocumentItem(Icons.shield_outlined, "Insurance", "Verified Sep 2023"),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Location Map Placeholder
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  padding: EdgeInsets.all(isMobile ? 20 : 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Live Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: const Text("LIVE", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          constraints: const BoxConstraints(minHeight: 220),
                                          width: double.infinity,
                                          color: AppColors.background,
                                          child: Center(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.map_outlined, size: 48, color: AppColors.border),
                                                  const SizedBox(height: 12),
                                                  const Text("Map View Unavailable", style: TextStyle(color: AppColors.subtle, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataRow _buildDeliveryRow(String id, String date, String customer, String time, String status) {
    return DataRow(cells: [
      DataCell(Text(id, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
      DataCell(Text(date, style: const TextStyle(color: AppColors.subtle))),
      DataCell(Text(customer)),
      DataCell(Text(time, style: const TextStyle(color: AppColors.subtle))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(status.toUpperCase(), style: const TextStyle(color: AppColors.green, fontSize: 9, fontWeight: FontWeight.bold)),
      )),
    ]);
  }

  Widget _buildReview(String name, String time, String comment, int stars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(name.substring(0, 1), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                Text(time, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(5, (index) => Icon(Icons.star, size: 16, color: index < stars ? AppColors.amber : AppColors.border)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(comment, style: const TextStyle(color: AppColors.subtle, height: 1.6, fontSize: 14)),
      ],
    );
  }

  Widget _buildDocumentItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
        ],
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String change;
  final Color color;

  const _StatCard(this.icon, this.title, this.value, this.change, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
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
                  Text(change, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(color: AppColors.subtle, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}



