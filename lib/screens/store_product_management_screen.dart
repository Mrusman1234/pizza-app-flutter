import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/firestore_constants.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/audit_service.dart';

class StoreProductManagementScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const StoreProductManagementScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<StoreProductManagementScreen> createState() => _StoreProductManagementScreenState();
}

class _StoreProductManagementScreenState extends State<StoreProductManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuditService _audit = AuditService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductDialog([Map<String, dynamic>? item]) {
    final bool isEditing = item != null;
    final TextEditingController nameController = TextEditingController(text: item?[FirestoreConstants.name]);
    final TextEditingController descController = TextEditingController(text: item?[FirestoreConstants.description]);
    final TextEditingController priceController = TextEditingController(text: item?[FirestoreConstants.price]?.toString());
    final TextEditingController imageController = TextEditingController(text: item?[FirestoreConstants.image]);
    final TextEditingController categoryController = TextEditingController(text: item?[FirestoreConstants.category]);
    bool isAvailable = item?['isAvailable'] ?? true;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(isEditing ? 'Edit Product' : 'Add New Product', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── IMAGE PICKER ──────────────────────────────────────────
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    setDialogState(() => isUploading = true);
                    final String? newUrl = await StorageService().pickAndUploadImage(
                      'products/${widget.restaurantId}/${DateTime.now().millisecondsSinceEpoch}.jpg'
                    );
                    if (newUrl != null) {
                      imageController.text = newUrl;
                    }
                    setDialogState(() => isUploading = false);
                  },
                  child: Container(
                    height: 100,
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
                              Icon(Icons.add_a_photo, color: AppColors.primary, size: 28),
                              SizedBox(height: 4),
                              Text('Upload Product Image', style: TextStyle(color: AppColors.subtle, fontSize: 10)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Product Name', labelStyle: TextStyle(color: AppColors.subtle)),
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
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppColors.subtle)),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Available', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: isAvailable,
                  onChanged: (val) => setDialogState(() => isAvailable = val),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price are required')));
                  return;
                }
                
                final data = {
                  FirestoreConstants.name: nameController.text.trim(),
                  FirestoreConstants.description: descController.text.trim(),
                  FirestoreConstants.price: double.tryParse(priceController.text) ?? 0.0,
                  FirestoreConstants.image: imageController.text.trim(),
                  FirestoreConstants.category: categoryController.text.trim(),
                  'isAvailable': isAvailable,
                  'restaurantId': widget.restaurantId,
                };

                try {
                  if (isEditing) {
                    await _firestoreService.updateMenuItem(widget.restaurantId, item![FirestoreConstants.id], data);
                  } else {
                    await _firestoreService.addMenuItem(widget.restaurantId, data);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Product updated' : 'Product added'))
                    );
                  }
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

  Future<void> _confirmDeleteProduct(Map<String, dynamic> item) async {
    final String productId = item[FirestoreConstants.id];
    final String productName = item[FirestoreConstants.name] ?? 'Unknown';
    final String? imageUrl = item[FirestoreConstants.image];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Product', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$productName"?', style: const TextStyle(color: AppColors.subtle)),
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
        await _firestoreService.deleteMenuItem(widget.restaurantId, productId);
        
        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.contains('firebasestorage')) {
          await StorageService().deleteFileByUrl(imageUrl);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.restaurantName, style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
          ],
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => _showProductDialog(),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(color: AppColors.subtle),
                prefixIcon: const Icon(Icons.search, color: AppColors.subtle),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMenuItems(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                var items = snapshot.data ?? [];
                
                if (_searchQuery.isNotEmpty) {
                  items = items.where((item) {
                    final name = (item[FirestoreConstants.name] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();
                }

                if (items.isEmpty) {
                  return const Center(child: Text('No products found.', style: TextStyle(color: AppColors.subtle)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item[FirestoreConstants.name] ?? 'Unknown';
                    final price = (item[FirestoreConstants.price] as num?)?.toDouble() ?? 0.0;
                    final category = item[FirestoreConstants.category] ?? 'General';
                    final isAvailable = item['isAvailable'] ?? true;
                    final imageUrl = item[FirestoreConstants.image];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null && imageUrl.toString().isNotEmpty
                            ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imagePlaceholder())
                            : _imagePlaceholder(),
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Rs. ${price.toStringAsFixed(0)}', 
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(isAvailable ? 'Available' : 'Out of Stock', 
                                    style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => _showProductDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _confirmDeleteProduct(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
}
