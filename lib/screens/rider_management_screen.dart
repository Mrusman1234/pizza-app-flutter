import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_sidebar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../services/firestore_service.dart';
import 'rider_profile_admin_screen.dart';

class RiderManagementScreen extends StatefulWidget {
  const RiderManagementScreen({super.key});

  @override
  State<RiderManagementScreen> createState() => _RiderManagementScreenState();
}

class _RiderManagementScreenState extends State<RiderManagementScreen> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};

  void _updateMarkers(List<Map<String, dynamic>> riders) {
    bool changed = false;
    for (var rider in riders) {
      final GeoPoint? loc = rider['currentLocation'] as GeoPoint?;
      final String id = rider[FirestoreConstants.id] ?? '';
      if (loc != null && id.isNotEmpty) {
        final marker = Marker(
          markerId: MarkerId(id),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: rider[FirestoreConstants.name] ?? 'Rider'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        );
        if (!_markers.containsKey(id) || _markers[id]!.position != marker.position) {
          _markers[id] = marker;
          changed = true;
        }
      }
    }
    if (changed) {
      setState(() {});
    }
  }

  void _showRiderDialog([Map<String, dynamic>? rider]) {
    final bool isEditing = rider != null;
    final TextEditingController nameController = TextEditingController(text: rider?[FirestoreConstants.name]);
    final TextEditingController emailController = TextEditingController(text: rider?[FirestoreConstants.email]);
    final TextEditingController zoneController = TextEditingController(text: rider?[FirestoreConstants.zone]);
    String status = rider?[FirestoreConstants.status] ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(isEditing ? 'Edit Rider' : 'Add New Rider', style: const TextStyle(color: AppColors.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: zoneController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Zone', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppColors.subtle)),
                  items: ['Active', 'Inactive', 'On Break'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => status = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 45),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () async {
                final String? adminId = FirebaseAuth.instance.currentUser?.uid;
                final data = {
                  FirestoreConstants.name: nameController.text,
                  FirestoreConstants.email: emailController.text,
                  FirestoreConstants.zone: zoneController.text,
                  FirestoreConstants.status: status,
                  FirestoreConstants.adminId: adminId,
                };
                if (isEditing) {
                  await FirestoreService().updateRider(rider[FirestoreConstants.id], data);
                } else {
                  await FirestoreService().addRider(data);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
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
        final bool isMobile = constraints.maxWidth < 1000;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Riders')) : null,
          appBar: isMobile 
            ? AppBar(
                backgroundColor: AppColors.card,
                title: const Text("Rider Management", style: TextStyle(color: Colors.white, fontSize: 18)),
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
              if (!isMobile) const AdminSidebar(activeItem: 'Riders'),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile) Header(onAdd: () => _showRiderDialog()),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: FirestoreService().getRiders(adminId: FirebaseAuth.instance.currentUser?.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final riders = snapshot.data ?? [];
                          // Update markers when data changes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _updateMarkers(riders);
                          });

                          return SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              children: [
                                if (isMobile) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _showRiderDialog(),
                                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                    label: const Text('Add New Rider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary, 
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Stats Grid
                                StatsGrid(riderCount: riders.length, isMobile: isMobile),
                                const SizedBox(height: 32),

                                // Fleet and Map Section
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final bool isStackLayout = constraints.maxWidth < 900;
                                    return Flex(
                                      direction: isStackLayout ? Axis.vertical : Axis.horizontal,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Active Riders Table
                                        Flexible(
                                          flex: isStackLayout ? 0 : 2,
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: AppColors.card,
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.all(24),
                                                  child: Text(
                                                    'Active Fleet List',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text),
                                                  ),
                                                ),
                                                const Divider(height: 1, color: AppColors.border),
                                                Theme(
                                                  data: Theme.of(context).copyWith(
                                                    dividerColor: AppColors.border,
                                                    textTheme: const TextTheme(
                                                      bodySmall: TextStyle(color: AppColors.text),
                                                    ),
                                                  ),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(minWidth: isStackLayout ? constraints.maxWidth - 48 : 0),
                                                      child: DataTable(
                                                        columnSpacing: 40,
                                                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.subtle),
                                                        dataTextStyle: const TextStyle(color: AppColors.text),
                                                        columns: const [
                                                          DataColumn(label: Text('Rider Profile')),
                                                          DataColumn(label: Text('Status')),
                                                          DataColumn(label: Text('Zone')),
                                                          DataColumn(label: Text('Rating')),
                                                          DataColumn(label: Text('Actions')),
                                                        ],
                                                        rows: riders.isEmpty 
                                                          ? [
                                                              const DataRow(cells: [
                                                                DataCell(Text("No riders found")),
                                                                DataCell(Text("-")),
                                                                DataCell(Text("-")),
                                                                DataCell(Text("-")),
                                                                DataCell(SizedBox()),
                                                              ])
                                                            ]
                                                          : riders.map((rider) => _buildDataRow(
                                                              context,
                                                              rider,
                                                            )).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isStackLayout) const SizedBox(height: 24) else const SizedBox(width: 24),
                                        // Live Map
                                        Flexible(
                                          flex: isStackLayout ? 0 : 1,
                                          child: Container(
                                            height: 400,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: AppColors.card,
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(24),
                                              child: Stack(
                                                children: [
                                                  GoogleMap(
                                                    initialCameraPosition: const CameraPosition(
                                                      target: LatLng(30.0444, 72.3444),
                                                      zoom: 12,
                                                    ),
                                                    markers: _markers.values.toSet(),
                                                    onMapCreated: (controller) {
                                                      _mapController = controller;
                                                      _updateMarkers(riders);
                                                    },
                                                    zoomControlsEnabled: false,
                                                    myLocationButtonEnabled: false,
                                                  ),
                                                  Positioned(
                                                    top: 16,
                                                    right: 16,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        "Monitoring ${riders.length} Active Riders",
                                                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ),
                                                  // Overlay when no markers
                                                  if (_markers.isEmpty)
                                                  Container(
                                                    color: Colors.black.withValues(alpha: 0.4),
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.map_outlined, size: 48, color: AppColors.primary),
                                                          const SizedBox(height: 12),
                                                          const Text("Live Fleet Map", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 18)),
                                                          const SizedBox(height: 4),
                                                          const Text("Waiting for rider GPS data...", style: TextStyle(fontSize: 14, color: AppColors.subtle)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
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
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, Map<String, dynamic> rider) {
    final String name = rider[FirestoreConstants.name] ?? 'Unnamed Rider';
    final String id = '#${rider[FirestoreConstants.id]?.toString().substring(0, 5) ?? 'N/A'}';
    final String status = rider[FirestoreConstants.status] ?? 'Active';
    final String zone = rider[FirestoreConstants.zone] ?? 'Downtown';
    final String rating = (rider[FirestoreConstants.rating] ?? 5.0).toString();
    final String avatar = rider[FirestoreConstants.image] ?? 'https://ui-avatars.com/api/?name=$name';
    
    final bool isActive = status == 'Active';
    return DataRow(cells: [
      DataCell(Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
              Text(id, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          )
        ],
      )),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
            color: isActive ? AppColors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(status,
            style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: isActive ? AppColors.green : Colors.blueAccent)),
      )),
      DataCell(Text(zone, style: const TextStyle(color: AppColors.text))),
      DataCell(Row(
        children: [
          const Icon(Icons.star, size: 16, color: AppColors.amber),
          const SizedBox(width: 4),
          Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text))
        ],
      )),
      DataCell(Row(
        children: [
          IconButton(icon: const Icon(Icons.visibility, size: 18, color: AppColors.subtle), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RiderProfileAdminScreen(rider: rider)));
          }),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.subtle), 
            onPressed: () => _showRiderDialog(rider),
          ),
          IconButton(
            icon: const Icon(Icons.block, color: AppColors.primary, size: 18), 
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.card,
                  title: const Text('Delete Rider', style: TextStyle(color: AppColors.text)),
                  content: const Text('Are you sure you want to delete this rider?', style: TextStyle(color: AppColors.subtle)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirestoreService().deleteRider(rider[FirestoreConstants.id]);
              }
            },
          ),
        ],
      ))
    ]);
  }
}

class Header extends StatelessWidget {
  final VoidCallback onAdd;
  const Header({super.key, required this.onAdd});

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
          final bool isCompact = constraints.maxWidth < 900;
          
          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Rider Management",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Monitor and manage your delivery fleet in real-time",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtle,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!isCompact) ...[
                SizedBox(
                  width: 320,
                  child: TextField(
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
                      hintText: "Search ID, name...",
                      hintStyle: const TextStyle(color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: isCompact ? const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : const Text('Add New Rider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// Removed local SideBar and _SidebarItem classes to use shared AdminSidebar component.

class StatsGrid extends StatelessWidget {
  final int riderCount;
  final bool isMobile;
  const StatsGrid({super.key, required this.riderCount, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: StatCard(icon: Icons.motorcycle, color: Colors.blue, title: 'Total Riders', value: riderCount.toString(), change: '+12%')),
              const SizedBox(width: 12),
              const Expanded(child: StatCard(icon: Icons.schedule, color: Colors.orange, title: 'Avg Time', value: '24.5 min', change: '-2.4%')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: StatCard(icon: Icons.local_shipping_outlined, color: Colors.green, title: 'Deliveries', value: '452', change: '+5.1%')),
              const SizedBox(width: 12),
              const Expanded(child: StatCard(icon: Icons.star_outline, color: Colors.amber, title: 'Satisfaction', value: '4.8', change: '+0.2')),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: StatCard(icon: Icons.motorcycle, color: Colors.blue, title: 'Total Riders', value: riderCount.toString(), change: '+12%')),
        const SizedBox(width: 16),
        const Expanded(child: StatCard(icon: Icons.schedule, color: Colors.orange, title: 'Avg Time', value: '24.5 min', change: '-2.4%')),
        const SizedBox(width: 16),
        const Expanded(child: StatCard(icon: Icons.local_shipping_outlined, color: Colors.green, title: 'Deliveries', value: '452', change: '+5.1%')),
        const SizedBox(width: 16),
        const Expanded(child: StatCard(icon: Icons.star_outline, color: Colors.amber, title: 'Satisfaction', value: '4.8', change: '+0.2')),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, value, change;

  const StatCard({super.key, required this.icon, required this.color, required this.title, required this.value, required this.change});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing more details on $title')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(change, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}


