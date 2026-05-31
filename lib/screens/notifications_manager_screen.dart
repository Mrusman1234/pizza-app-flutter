import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/firestore_service.dart';

class NotificationsManagerScreen extends StatelessWidget {
  const NotificationsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 1000;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Notifications')) : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Notifications'),
              
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        backgroundColor: AppColors.background,
                        elevation: 0,
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    const NotificationsHeader(),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: FirestoreService().getAdminNotifications(
                          adminId: FirebaseAuth.instance.currentUser?.uid,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final notifications = snapshot.data ?? [];

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: LayoutBuilder(
                              builder: (context, innerConstraints) {
                                final bool useSingleColumn = innerConstraints.maxWidth < 800;
                                
                                if (useSingleColumn) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const StatsRow(),
                                      const SizedBox(height: 32),
                                      ActiveCampaignsTable(notifications: notifications),
                                      const SizedBox(height: 32),
                                      const CampaignTemplatesGrid(),
                                      const SizedBox(height: 32),
                                      const AudienceSegmentsCard(),
                                      const SizedBox(height: 24),
                                      const UpcomingScheduleCard(),
                                      const SizedBox(height: 24),
                                      const QuickTipCard(),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const StatsRow(),
                                          const SizedBox(height: 32),
                                          ActiveCampaignsTable(notifications: notifications),
                                          const SizedBox(height: 32),
                                          const CampaignTemplatesGrid(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: const [
                                          AudienceSegmentsCard(),
                                          SizedBox(height: 24),
                                          UpcomingScheduleCard(),
                                          SizedBox(height: 24),
                                          QuickTipCard(),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
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
      },
    );
  }
}

// ================= Header =================
class NotificationsHeader extends StatefulWidget {
  const NotificationsHeader({super.key});

  @override
  State<NotificationsHeader> createState() => _NotificationsHeaderState();
}

class _NotificationsHeaderState extends State<NotificationsHeader> {
  void _showCreateNotificationDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    String target = 'All Users';
    String type = 'Push';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Create New Campaign', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Campaign Title',
                    labelStyle: TextStyle(color: AppColors.subtle),
                  ),
                ),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Message Body',
                    labelStyle: TextStyle(color: AppColors.subtle),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: target,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    labelStyle: TextStyle(color: AppColors.subtle),
                  ),
                  items: ['All Users', 'Dormant Users', 'High Spenders', 'New Signups']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => target = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Channel',
                    labelStyle: TextStyle(color: AppColors.subtle),
                  ),
                  items: ['Push', 'Email', 'SMS', 'In-App']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => type = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                final data = {
                  FirestoreConstants.title: titleController.text,
                  FirestoreConstants.body: bodyController.text,
                  FirestoreConstants.target: target,
                  FirestoreConstants.type: type,
                  FirestoreConstants.status: FirestoreConstants.statusSent,
                };

                await FirestoreService().addAdminNotification(data);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Send Campaign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 600;
          
          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Create and manage customer push notifications",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtle,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              isCompact 
                ? IconButton(
                    onPressed: _showCreateNotificationDialog,
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                  )
                : ElevatedButton.icon(
                    onPressed: _showCreateNotificationDialog,
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      'NEW CAMPAIGN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

// ================= Left Column Widgets =================
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: const [
              StatMiniCard(title: "DELIVERED", value: "124k", icon: Icons.done_all, color: AppColors.green),
              SizedBox(height: 16),
              StatMiniCard(title: "OPEN RATE", value: "18.4%", icon: Icons.visibility_outlined, color: Colors.blue),
              SizedBox(height: 16),
              StatMiniCard(title: "CONVERSION", value: "4.2%", icon: Icons.shopping_bag_outlined, color: Colors.orange),
            ],
          );
        }
        return Row(
          children: const [
            Expanded(child: StatMiniCard(title: "DELIVERED", value: "124k", icon: Icons.done_all, color: AppColors.green)),
            SizedBox(width: 16),
            Expanded(child: StatMiniCard(title: "OPEN RATE", value: "18.4%", icon: Icons.visibility_outlined, color: Colors.blue)),
            SizedBox(width: 16),
            Expanded(child: StatMiniCard(title: "CONVERSION", value: "4.2%", icon: Icons.shopping_bag_outlined, color: Colors.orange)),
          ],
        );
      },
    );
  }
}

class StatMiniCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const StatMiniCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insights for $title...')));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, 
                      style: const TextStyle(color: AppColors.subtle, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ActiveCampaignsTable extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  const ActiveCampaignsTable({super.key, required this.notifications});

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
          const Text("Active Campaigns", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          notifications.isEmpty 
          ? const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No notifications or campaigns found.", style: TextStyle(color: AppColors.subtle)),
            ))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Title", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle), overflow: TextOverflow.ellipsis)),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Sent To", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle), overflow: TextOverflow.ellipsis)),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle), overflow: TextOverflow.ellipsis)),
                        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle), overflow: TextOverflow.ellipsis)),
                      ]
                    ),
                    ...notifications.map((notif) => _buildRow(
                      context, 
                      notif[FirestoreConstants.title] ?? 'No Title', 
                      notif[FirestoreConstants.target] ?? 'All Users', 
                      notif[FirestoreConstants.type] ?? 'Push', 
                      notif[FirestoreConstants.status] ?? FirestoreConstants.statusSent, 
                      _getStatusColor(notif[FirestoreConstants.status])
                    )),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == FirestoreConstants.statusSent) return AppColors.green;
    if (status == FirestoreConstants.statusRunning) return AppColors.green;
    if (status == FirestoreConstants.statusScheduled) return Colors.blue;
    if (status == FirestoreConstants.statusFailed) return AppColors.primary;
    return AppColors.subtle;
  }

  TableRow _buildRow(BuildContext context, String name, String sent, String rate, String status, Color color) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: [
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign details for $name...')));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(name, 
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                overflow: TextOverflow.ellipsis),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16), 
          child: Text(sent, 
              style: const TextStyle(color: AppColors.subtle),
              overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16), 
          child: Text(rate, 
              style: const TextStyle(color: AppColors.subtle),
              overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              UnconstrainedBox(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, 
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.primary, size: 18),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('Delete Campaign', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure you want to delete this notification campaign?', style: TextStyle(color: AppColors.subtle)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.primary))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final notifId = notifications.firstWhere((n) => n[FirestoreConstants.title] == name)[FirestoreConstants.id];
                    await FirestoreService().deleteAdminNotification(notifId);
                  }
                },
              ),
            ],
          ),
        ),
      ]
    );
  }
}

class CampaignTemplatesGrid extends StatelessWidget {
  const CampaignTemplatesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Message Templates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 3;
            if (constraints.maxWidth < 600) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 2;
            }
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                TemplateCard(title: "Order Received", body: "Your pizza is in the oven! 🍕"),
                TemplateCard(title: "Promo Discount", body: "Get 20% OFF today only! Use code PIZZA20."),
                TemplateCard(title: "Rider Nearby", body: "Your rider Ahmed is 2 mins away! 🏍️"),
              ],
            );
          },
        )
      ],
    );
  }
}

class TemplateCard extends StatelessWidget {
  final String title, body;
  const TemplateCard({super.key, required this.title, required this.body});

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
          Text(title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(body, 
              style: const TextStyle(color: AppColors.subtle, fontSize: 13), 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          TextButton(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Using template: $title')));
          }, child: const Text("Use Template", 
              style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ================= Right Column Widgets =================
class AudienceSegmentsCard extends StatelessWidget {
  const AudienceSegmentsCard({super.key});

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
          const Text("Audience Segments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          _buildSegmentRow(context, "Dormant Users", "2,450", Colors.orange),
          const Divider(height: 24, color: AppColors.border),
          _buildSegmentRow(context, "High Spenders", "1,120", AppColors.green),
          const Divider(height: 24, color: AppColors.border),
          _buildSegmentRow(context, "New Signups", "850", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(BuildContext context, String label, String count, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Segment: $label')));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}

class UpcomingScheduleCard extends StatelessWidget {
  const UpcomingScheduleCard({super.key});

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
          const Text("Upcoming Schedule", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editing Brunch Campaign...')));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Tomorrow, 10:00 AM", 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text("Sunday Brunch Campaign", 
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Divider(height: 32, color: AppColors.border),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editing CL Promo...')));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Nov 24, 06:00 PM", 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.subtle),
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text("Champions League Promo", 
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickTipCard extends StatelessWidget {
  const QuickTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stay creative with your pushes! 🍕')));
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.white, size: 28),
            SizedBox(height: 16),
            Text("Quick Tip", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 8),
            Text("Using emojis in your push notification titles can increase open rates by up to 25%!", 
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}


