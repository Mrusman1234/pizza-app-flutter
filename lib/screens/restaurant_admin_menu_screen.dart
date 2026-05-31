import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/firestore_constants.dart';
import '../providers/restaurant_admin_provider.dart';
import '../services/audit_service.dart';

class RestaurantAdminMenuScreen extends StatefulWidget {
  const RestaurantAdminMenuScreen({super.key});

  @override
  State<RestaurantAdminMenuScreen> createState() => _RestaurantAdminMenuScreenState();
}

class _RestaurantAdminMenuScreenState extends State<RestaurantAdminMenuScreen> {
  final _audit = AuditService();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantAdminProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu Management', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.card,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showMenuItemDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: provider.menuStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final items = snapshot.data?.docs ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No menu items found.', style: TextStyle(color: AppColors.subtle)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data();
              return _buildMenuTile(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuTile(String id, Map<String, dynamic> data) {
    final name = data[FirestoreConstants.name] ?? 'Unknown';
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final isAvailable = data['isAvailable'] ?? true;
    final imageUrl = data['image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null 
            ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, 
                errorBuilder: (_, _, _) => _imagePlaceholder())
            : _imagePlaceholder(),
        ),
        title: Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rs ${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAvailable ? AppColors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(isAvailable ? 'Available' : 'Unavailable', 
                  style: TextStyle(color: isAvailable ? AppColors.green : Colors.red, fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.subtle),
          onSelected: (val) {
            if (val == 'edit') _showMenuItemDialog(id: id, initialData: data);
            if (val == 'toggle') _toggleAvailability(id, isAvailable);
            if (val == 'delete') _deleteItem(id, name);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Item')),
            PopupMenuItem(value: 'toggle', child: Text(isAvailable ? 'Mark Unavailable' : 'Mark Available')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Item', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 60, height: 60,
      color: AppColors.background,
      child: const Icon(Icons.restaurant, color: AppColors.subtle),
    );
  }

  Future<void> _toggleAvailability(String id, bool current) async {
    final provider = context.read<RestaurantAdminProvider>();
    final restId = provider.restaurantId;
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.restaurants)
        .doc(restId)
        .collection(FirestoreConstants.menu)
        .doc(id)
        .update({'isAvailable': !current});
    
    await _audit.logMenuUpdate(restId, id, 'UPDATE_MENU_ITEM');
  }

  Future<void> _deleteItem(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final provider = context.read<RestaurantAdminProvider>();
      final restId = provider.restaurantId;
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.restaurants)
          .doc(restId)
          .collection(FirestoreConstants.menu)
          .doc(id)
          .delete();
      
      await _audit.logMenuUpdate(restId, id, 'DELETE_MENU_ITEM');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted')));
    }
  }

  void _showMenuItemDialog({String? id, Map<String, dynamic>? initialData}) {
    final isEdit = id != null;
    final nameController = TextEditingController(text: initialData?[FirestoreConstants.name]);
    final priceController = TextEditingController(text: initialData?['price']?.toString());
    final descriptionController = TextEditingController(text: initialData?['description']);
    final imageController = TextEditingController(text: initialData?['image']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item', style: const TextStyle(color: AppColors.text)),
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
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
              TextField(
                controller: imageController,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(labelText: 'Image URL', labelStyle: TextStyle(color: AppColors.subtle)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (name.isEmpty) return;

              final provider = context.read<RestaurantAdminProvider>();
              final restId = provider.restaurantId;
              final col = FirebaseFirestore.instance
                  .collection(FirestoreConstants.restaurants)
                  .doc(restId)
                  .collection(FirestoreConstants.menu);

              final data = {
                FirestoreConstants.name: name,
                'price': price,
                'description': descriptionController.text.trim(),
                'image': imageController.text.trim(),
                'isAvailable': initialData?['isAvailable'] ?? true,
                'restaurantId': restId,
              };

              if (isEdit) {
                await col.doc(id).update(data);
                await _audit.logMenuUpdate(restId, id, 'UPDATE_MENU_ITEM');
              } else {
                final docRef = await col.add(data);
                await _audit.logMenuUpdate(restId, docRef.id, 'ADD_MENU_ITEM');
              }

              if (context.mounted) {
                Navigator.pop(ctx);
                messenger.showSnackBar(SnackBar(content: Text(isEdit ? 'Item updated' : 'Item added')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
