import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _setAsDefault(String addressId) async {
    if (userId == null) return;
    try {
      await _firestoreService.setDefaultAddress(userId!, addressId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    if (userId == null) return;
    try {
      await _firestoreService.deleteAddress(userId!, addressId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please login to manage addresses")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Delivery Addresses'),
            Text('Pizza Hub Vehari', style: TextStyle(fontSize: 10, color: AppColors.primary)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getAddresses(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final addresses = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: addresses.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          return _buildAddressCard(addr);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomButton(
                  text: 'Add New Address',
                  onPressed: () => Navigator.pushNamed(context, RouteNames.addAddress),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    final bool isDefault = addr['isDefault'] ?? false;
    final String label = addr['type'] ?? 'Home';
    
    IconData icon;
    switch (label) {
      case 'Home': icon = Icons.home_rounded; break;
      case 'Office': icon = Icons.work_rounded; break;
      default: icon = Icons.location_on_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? AppColors.primary : AppColors.border, width: isDefault ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: () => Navigator.pop(context, addr['address']),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDefault ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: isDefault ? Colors.white : AppColors.subtle, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        if (isDefault)
                          const Text('Default Address', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _buildPopupMenu(addr),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                addr['address'] ?? '',
                style: const TextStyle(color: AppColors.subtle, fontSize: 14, height: 1.4),
              ),
              if (!isDefault) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.border),
                TextButton(
                  onPressed: () => _setAsDefault(addr['id']),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Set as default', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(Map<String, dynamic> addr) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.subtle),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.pushNamed(context, RouteNames.addAddress, arguments: addr);
        } else if (value == 'delete') {
          _deleteAddress(addr['id']);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded, size: 64, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          const Text('No addresses yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Add your delivery address to get started', style: TextStyle(color: AppColors.subtle)),
        ],
      ),
    );
  }
}



