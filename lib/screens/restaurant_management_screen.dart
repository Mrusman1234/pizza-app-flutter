import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../routes/route_names.dart';

class RestaurantManagementScreen extends StatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  State<RestaurantManagementScreen> createState() => _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState extends State<RestaurantManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showRestaurantDialog([Map<String, dynamic>? restaurant]) {
    final bool isEditing = restaurant != null;
    final TextEditingController nameController = TextEditingController(text: restaurant?[FirestoreConstants.name]);
    final TextEditingController descController = TextEditingController(text: restaurant?[FirestoreConstants.description]);
    final TextEditingController imageController = TextEditingController(text: restaurant?[FirestoreConstants.image]);
    final TextEditingController timeController = TextEditingController(text: restaurant?[FirestoreConstants.time]);
    final TextEditingController deliveryController = TextEditingController(text: restaurant?[FirestoreConstants.delivery]);
    final TextEditingController latController = TextEditingController(text: restaurant?[FirestoreConstants.latitude]?.toString());
    final TextEditingController lngController = TextEditingController(text: restaurant?[FirestoreConstants.longitude]?.toString());
    final TextEditingController radiusController = TextEditingController(text: restaurant?[FirestoreConstants.deliveryRadius]?.toString() ?? '10.0');

    Map<String, dynamic> hours = restaurant?['operatingHours'] ?? {
      'monday': {'open': '09:00', 'close': '22:00'},
      'tuesday': {'open': '09:00', 'close': '22:00'},
      'wednesday': {'open': '09:00', 'close': '22:00'},
      'thursday': {'open': '09:00', 'close': '22:00'},
      'friday': {'open': '09:00', 'close': '23:00'},
      'saturday': {'open': '09:00', 'close': '23:00'},
      'sunday': {'open': '09:00', 'close': '22:00'},
    };

    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(isEditing ? 'Edit Store' : 'Add New Store', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    setModalState(() => isUploading = true);
                    final String? newUrl = await StorageService().pickAndUploadImage(
                      'restaurants/${DateTime.now().millisecondsSinceEpoch}.jpg'
                    );
                    if (newUrl != null) {
                      imageController.text = newUrl;
                    }
                    setModalState(() => isUploading = false);
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: isUploading 
                      ? const Center(child: CircularProgressIndicator())
                      : imageController.text.isNotEmpty 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(imageController.text, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                              SizedBox(height: 8),
                              Text('Upload Store Image', style: TextStyle(color: AppColors.subtle, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Store Name', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: timeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Delivery Time (e.g. 20-30 min)', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                TextField(
                  controller: deliveryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Delivery Fee', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const Text('Location & Geofencing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Latitude', labelStyle: TextStyle(color: AppColors.subtle)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Longitude', labelStyle: TextStyle(color: AppColors.subtle)),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: radiusController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Delivery Radius (km)', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showHoursDialog(context, hours, (newHours) {
                    setModalState(() => hours = newHours);
                  }),
                  icon: const Icon(Icons.access_time_filled, size: 18),
                  label: const Text('Configure Operating Hours'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store name is required')));
                  return;
                }
                final String? adminId = FirebaseAuth.instance.currentUser?.uid;
                final data = {
                  FirestoreConstants.name: nameController.text.trim(),
                  FirestoreConstants.description: descController.text.trim(),
                  FirestoreConstants.image: imageController.text.trim(),
                  FirestoreConstants.time: timeController.text.trim(),
                  FirestoreConstants.delivery: deliveryController.text.trim(),
                  FirestoreConstants.adminId: adminId,
                  FirestoreConstants.latitude: double.tryParse(latController.text),
                  FirestoreConstants.longitude: double.tryParse(lngController.text),
                  FirestoreConstants.deliveryRadius: double.tryParse(radiusController.text) ?? 10.0,
                  'operatingHours': hours,
                };
                
                try {
                  if (isEditing) {
                    await _firestoreService.updateRestaurant(restaurant[FirestoreConstants.id], data);
                  } else {
                    await _firestoreService.addRestaurant(data);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHoursDialog(BuildContext context, Map<String, dynamic> currentHours, Function(Map<String, dynamic>) onSave) {
    final Map<String, dynamic> workingHours = Map<String, dynamic>.from(currentHours);
    final List<String> days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Operating Hours (24h format)', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text(day.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => workingHours[day]['open'] = v,
                          controller: TextEditingController(text: workingHours[day]['open']),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: const InputDecoration(hintText: 'Open (09:00)', isDense: true),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: TextStyle(color: Colors.white))),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => workingHours[day]['close'] = v,
                          controller: TextEditingController(text: workingHours[day]['close']),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: const InputDecoration(hintText: 'Close (22:00)', isDense: true),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                onSave(workingHours);
                Navigator.pop(context);
              },
              child: const Text('Save Hours'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteStore(Map<String, dynamic> restaurant) async {
    final String id = restaurant[FirestoreConstants.id];
    final String name = restaurant[FirestoreConstants.name] ?? 'Unnamed Store';
    final String? imageUrl = restaurant[FirestoreConstants.image];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Restaurant', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$name"? This will permanently remove the store and its menu.', 
            style: const TextStyle(color: AppColors.subtle)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteRestaurant(id);
        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.contains('firebasestorage')) {
          await StorageService().deleteFileByUrl(imageUrl);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Stores')) : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Stores'),
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
                        title: const Text("Store Management", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    _buildHeader(),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _firestoreService.getRestaurants(adminId: FirebaseAuth.instance.currentUser?.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final restaurants = snapshot.data ?? [];
                          if (restaurants.isEmpty) {
                            return _buildEmptyState();
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: restaurants.length,
                            itemBuilder: (context, index) => _buildRestaurantCard(restaurants[index]),
                          );
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Store Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Add, edit and manage your restaurant locations", style: TextStyle(fontSize: 14, color: AppColors.subtle)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showRestaurantDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add New Store"),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final String restaurantId = restaurant[FirestoreConstants.id];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  restaurant[FirestoreConstants.image] ?? 'https://via.placeholder.com/300x150',
                  height: 150, width: double.infinity, fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showRestaurantDialog(restaurant)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteStore(restaurant)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant[FirestoreConstants.name] ?? 'Unnamed Store', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                Text(restaurant[FirestoreConstants.description] ?? '', style: const TextStyle(color: AppColors.subtle, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.adminStoreProducts, arguments: {'id': restaurantId, 'name': restaurant[FirestoreConstants.name]}),
                  child: const Text("Manage Products"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No stores found", style: TextStyle(color: Colors.white)));
  }
}
