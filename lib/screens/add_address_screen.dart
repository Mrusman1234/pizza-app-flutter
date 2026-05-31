import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  String _selectedType = 'Home';
  bool _isSaving = false;
  bool _isFetchingLocation = false;
  bool _isInitialized = false;
  String? _editingAddressId;
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  double? _lat;
  double? _lng;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _editingAddressId = args['id'];
        _addressController.text = args['address'] ?? '';
        _labelController.text = args['additionalInfo'] ?? '';
        _selectedType = args['type'] ?? 'Home';
        _lat = args['lat'];
        _lng = args['lng'];
      }
      _isInitialized = true;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    final position = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        // In a real app, you would use reverse geocoding to fill the address controller
        _addressController.text = "Pinned Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch location. Please check permissions.')),
      );
    }
    setState(() => _isFetchingLocation = false);
  }

  Future<void> _handleSaveAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter address details')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final addressData = {
        'address': address,
        'additionalInfo': _labelController.text.trim(),
        'type': _selectedType,
        'lat': _lat ?? 30.0442,
        'lng': _lng ?? 72.3552,
      };

      if (_editingAddressId != null) {
        await _firestoreService.updateAddress(user.uid, _editingAddressId!, addressData);
      } else {
        final addresses = await _firestoreService.getAddresses(user.uid).first;
        addressData['isDefault'] = addresses.isEmpty;
        await _firestoreService.saveAddress(user.uid, addressData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingAddressId != null ? 'Address updated' : 'Address saved'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_editingAddressId != null ? 'Edit Address' : 'Add New Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Save address as'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeOption('Home', Icons.home_rounded),
                const SizedBox(width: 12),
                _buildTypeOption('Office', Icons.work_rounded),
                const SizedBox(width: 12),
                _buildTypeOption('Other', Icons.location_on_rounded),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionLabel('Address Details'),
                TextButton.icon(
                  onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                  icon: _isFetchingLocation 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.my_location, size: 16, color: AppColors.primary),
                  label: const Text('Use My Location', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              hint: 'e.g. House #123, Street #5, Sector G-11',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('Additional Info (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _labelController,
              hint: 'e.g. Floor #2, Apartment #301',
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: _editingAddressId != null ? 'Update Address' : 'Save Address',
              isLoading: _isSaving,
              onPressed: _handleSaveAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTypeOption(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.subtle),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.subtle,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}



