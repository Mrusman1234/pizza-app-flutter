import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/admin_sidebar.dart';
import '../../routes/route_names.dart';
import '../../services/firestore_service.dart';
import '../../models/app_config_model.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  final _deliveryFeeController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _minVersionController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _supportEmailController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _taxRateController.dispose();
    _minVersionController.dispose();
    _supportPhoneController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final config = {
        'baseDeliveryFee': double.tryParse(_deliveryFeeController.text) ?? 50.0,
        'taxRate': (double.tryParse(_taxRateController.text) ?? 5.0) / 100,
        'min_version': _minVersionController.text.trim(),
        'supportPhone': _supportPhoneController.text.trim(),
        'supportEmail': _supportEmailController.text.trim(),
      };
      
      await _firestoreService.updateAppConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration updated successfully!'), backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Settings')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  title: const Text("Settings", style: TextStyle(color: Colors.white, fontSize: 18)),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Settings'),
              Expanded(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _firestoreService.getAppConfig(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && _deliveryFeeController.text.isEmpty) {
                      final config = AppConfigModel.fromMap(snapshot.data!);
                      _deliveryFeeController.text = config.baseDeliveryFee.toStringAsFixed(0);
                      _taxRateController.text = (config.taxRate * 100).toStringAsFixed(0);
                      _minVersionController.text = config.minVersion;
                      _supportPhoneController.text = config.supportPhone;
                      _supportEmailController.text = config.supportEmail;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobile) _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 800),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader('Global System Configuration'),
                                    const SizedBox(height: 24),
                                    _buildConfigCard(),
                                    const SizedBox(height: 32),
                                    _buildSectionHeader('Account Actions'),
                                    const SizedBox(height: 16),
                                    _buildSettingTile(
                                      isMobile: isMobile,
                                      icon: Icons.logout,
                                      title: 'Sign Out',
                                      subtitle: 'Safely log out of the admin panel',
                                      iconColor: AppColors.primary,
                                      onTap: () async {
                                        await FirebaseAuth.instance.signOut();
                                        if (context.mounted) {
                                          Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Manage your global system configuration and preferences', style: TextStyle(fontSize: 14, color: AppColors.subtle)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveConfig,
            icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField('Base Delivery Fee (Rs.)', _deliveryFeeController, Icons.delivery_dining)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Global Tax Rate (%)', _taxRateController, Icons.percent)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Minimum App Version (e.g. 1.0.5)', _minVersionController, Icons.system_update_alt),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField('Support Phone', _supportPhoneController, Icons.phone)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Support Email', _supportEmailController, Icons.email)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildSettingTile({required bool isMobile, required IconData icon, required String title, required String subtitle, Color? iconColor, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (iconColor ?? Colors.blue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.subtle, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.subtle),
      ),
    );
  }
}
