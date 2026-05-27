import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/firestore_service.dart';

class RestaurantManagementScreen extends StatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  State<RestaurantManagementScreen> createState() => _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState extends State<RestaurantManagementScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showRestaurantDialog([Map<String, dynamic>? restaurant]) {
    final bool isEditing = restaurant != null;
    final TextEditingController nameController = TextEditingController(text: restaurant?[FirestoreConstants.name]);
    final TextEditingController descController = TextEditingController(text: restaurant?[FirestoreConstants.description]);
    final TextEditingController imageController = TextEditingController(text: restaurant?[FirestoreConstants.image]);
    final TextEditingController timeController = TextEditingController(text: restaurant?[FirestoreConstants.time]);
    final TextEditingController deliveryController = TextEditingController(text: restaurant?[FirestoreConstants.delivery]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(isEditing ? 'Edit Store' : 'Add New Store', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                controller: imageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Image URL', labelStyle: TextStyle(color: AppColors.subtle)),
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
              if (nameController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store name is required')));
                }
                return;
              }
              final String? adminId = FirebaseAuth.instance.currentUser?.uid;
              final data = {
                FirestoreConstants.name: nameController.text,
                FirestoreConstants.description: descController.text,
                FirestoreConstants.image: imageController.text,
                FirestoreConstants.time: timeController.text,
                FirestoreConstants.delivery: deliveryController.text,
                FirestoreConstants.adminId: adminId,
              };
              if (isEditing) {
                await FirestoreService().updateRestaurant(restaurant[FirestoreConstants.id], data);
              } else {
                await FirestoreService().addRestaurant(data);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showMenuItemDialog(String restaurantId, [Map<String, dynamic>? item]) {
    final bool isEditing = item != null;
    final TextEditingController nameController = TextEditingController(text: item?[FirestoreConstants.name]);
    final TextEditingController descController = TextEditingController(text: item?[FirestoreConstants.description]);
    final TextEditingController priceController = TextEditingController(text: item?[FirestoreConstants.price]?.toString());
    final TextEditingController imageController = TextEditingController(text: item?[FirestoreConstants.image]);
    final TextEditingController categoryController = TextEditingController(text: item?[FirestoreConstants.category]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Item Name', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
              TextField(
                controller: imageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Image URL', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
              TextField(
                controller: categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppColors.subtle)),
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
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price are required')));
                }
                return;
              }
              final data = {
                FirestoreConstants.name: nameController.text,
                FirestoreConstants.description: descController.text,
                FirestoreConstants.price: double.tryParse(priceController.text) ?? 0.0,
                FirestoreConstants.image: imageController.text,
                FirestoreConstants.category: categoryController.text,
              };
              if (isEditing) {
                await FirestoreService().updateMenuItem(restaurantId, item[FirestoreConstants.id], data);
              } else {
                await FirestoreService().addMenuItem(restaurantId, data);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showMenuManager(Map<String, dynamic> restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Menu: ${restaurant[FirestoreConstants.name]}", 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showMenuItemDialog(restaurant[FirestoreConstants.id]),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getMenuItems(restaurant[FirestoreConstants.id]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: AppColors.primary)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) return const Center(child: Text("No menu items", style: TextStyle(color: AppColors.subtle)));
                  
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.border,
                          backgroundImage: (item[FirestoreConstants.image] != null && item[FirestoreConstants.image].toString().isNotEmpty)
                            ? NetworkImage(item[FirestoreConstants.image])
                            : null,
                          child: (item[FirestoreConstants.image] == null || item[FirestoreConstants.image].toString().isEmpty)
                            ? const Icon(Icons.fastfood, color: AppColors.subtle)
                            : null,
                        ),
                        title: Text(item[FirestoreConstants.name] ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text("Rs. ${item[FirestoreConstants.price]}", style: const TextStyle(color: AppColors.subtle)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => _showMenuItemDialog(restaurant[FirestoreConstants.id], item)),
                            IconButton(icon: const Icon(Icons.delete, color: AppColors.primary), onPressed: () => FirestoreService().deleteMenuItem(restaurant[FirestoreConstants.id], item[FirestoreConstants.id])),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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
                        stream: FirestoreService().getRestaurants(adminId: FirebaseAuth.instance.currentUser?.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
                                    const SizedBox(height: 16),
                                    Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => setState(() {}),
                                      child: const Text("Retry"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final restaurants = snapshot.data ?? [];

                          if (restaurants.isEmpty) {
                            return _buildEmptyState();
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 3;
                              if (constraints.maxWidth < 650) {
                                crossAxisCount = 1;
                              } else if (constraints.maxWidth < 1100) {
                                crossAxisCount = 2;
                              }
                              
                              final double paddingAndSpacing = 48.0 + (crossAxisCount - 1) * 24.0;
                              final double cardWidth = (constraints.maxWidth - paddingAndSpacing) / crossAxisCount;
                              final double childAspectRatio = cardWidth / 370.0;

                              return GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: childAspectRatio > 0.55 ? childAspectRatio : 0.55,
                                ),
                                itemCount: restaurants.length,
                                itemBuilder: (context, index) {
                                  final restaurant = restaurants[index];
                                  return _buildRestaurantCard(restaurant);
                                },
                              );
                            },
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
                      "Store Management",
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
                      "Add, edit and manage your restaurant locations",
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
                    onPressed: () => _showRestaurantDialog(),
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _showRestaurantDialog(),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text("Add New Store", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              restaurant[FirestoreConstants.image] ?? 'https://via.placeholder.com/300x150',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                color: AppColors.border,
                child: const Icon(Icons.broken_image, color: AppColors.subtle, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant[FirestoreConstants.name] ?? 'Unnamed Store',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            (restaurant[FirestoreConstants.rating] ?? 0.0).toString(),
                            style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant[FirestoreConstants.description] ?? 'No description available.',
                  style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(Icons.access_time, restaurant[FirestoreConstants.time] ?? '20-30 min'),
                    const SizedBox(width: 8),
                    _buildInfoItem(Icons.delivery_dining, restaurant[FirestoreConstants.delivery] ?? 'Free'),
                  ],
                ),
                const Divider(height: 32, color: AppColors.border),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showMenuManager(restaurant),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Menu"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRestaurantDialog(restaurant),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Edit"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text, 
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: AppColors.muted),
          const SizedBox(height: 16),
          const Text("No stores found", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Start by adding a new restaurant to the platform.", style: TextStyle(color: AppColors.subtle)),
        ],
      ),
    );
  }
}


