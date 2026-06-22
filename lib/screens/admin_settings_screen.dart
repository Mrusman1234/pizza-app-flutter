import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_sidebar.dart';
import '../core/constants/app_colors.dart';
import '../providers/config_provider.dart';
import '../models/app_config_model.dart';
import '../services/firestore_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // ── Controllers ──────────────────────────────────────────────────────────
  final _appNameController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _supportWhatsAppController = TextEditingController();
  final _defaultCommissionController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _minVersionController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _taxRateController = TextEditingController();

  bool _maintenanceMode = false;
  bool _ordersEnabled = true;
  bool _notificationsEnabled = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final configProvider = Provider.of<ConfigProvider>(context);
      if (!configProvider.isLoading && configProvider.config != null) {
        final config = configProvider.config!;
        _appNameController.text = config.appName;
        _supportEmailController.text = config.supportEmail;
        _supportPhoneController.text = config.supportPhone;
        _supportWhatsAppController.text = config.supportWhatsApp;
        _defaultCommissionController.text = config.defaultCommission.toString();
        _minOrderController.text = config.minOrderAmount.toString();
        _deliveryFeeController.text = config.baseDeliveryFee.toString();
        _minVersionController.text = config.minVersion;
        _latestVersionController.text = config.latestVersion;
        _taxRateController.text = config.taxRate.toString();
        _maintenanceMode = config.maintenanceMode;
        _ordersEnabled = config.ordersEnabled;
        _notificationsEnabled = config.notificationsEnabled;
        _isInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _supportWhatsAppController.dispose();
    _defaultCommissionController.dispose();
    _minOrderController.dispose();
    _deliveryFeeController.dispose();
    _minVersionController.dispose();
    _latestVersionController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_appNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App Name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      final newConfig = AppConfigModel(
        appName: _appNameController.text.trim(),
        supportEmail: _supportEmailController.text.trim(),
        supportPhone: _supportPhoneController.text.trim(),
        supportWhatsApp: _supportWhatsAppController.text.trim(),
        defaultCommission: double.tryParse(_defaultCommissionController.text) ?? 10.0,
        minOrderAmount: double.tryParse(_minOrderController.text) ?? 200.0,
        baseDeliveryFee: double.tryParse(_deliveryFeeController.text) ?? 50.0,
        taxRate: double.tryParse(_taxRateController.text) ?? 0.05,
        minVersion: _minVersionController.text.trim(),
        latestVersion: _latestVersionController.text.trim(),
        maintenanceMode: _maintenanceMode,
        ordersEnabled: _ordersEnabled,
        notificationsEnabled: _notificationsEnabled,
      );

      await configProvider.updateConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Settings')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  elevation: 0,
                  title: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
                  iconTheme: const IconThemeData(color: Colors.white),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Settings'),
              Expanded(
                child: configProvider.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildBody(constraints),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _buildContent(constraints),
        ),
      ),
    );
  }

  Widget _buildContent(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),

        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildGeneralSettingsCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildPlatformSettingsCard()),
              ],
            ),
          )
        else ...[
          _buildGeneralSettingsCard(),
          const SizedBox(height: 20),
          _buildPlatformSettingsCard(),
        ],

        const SizedBox(height: 20),
        _buildToggleSettingsCard(),
        const SizedBox(height: 20),
        _buildDangerZoneCard(),
        const SizedBox(height: 32),
        _buildSaveButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage platform configuration and preferences',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.subtle,
          ),
        ),
      ],
    );
  }

  // ── General Settings Card ─────────────────────────────────────────────────
  Widget _buildGeneralSettingsCard() {
    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardTitle(
              icon: Icons.settings_outlined,
              label: 'General',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _appNameController,
              label: 'App Name',
              icon: Icons.apps,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _supportEmailController,
              label: 'Support Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _supportPhoneController,
              label: 'Support Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _supportWhatsAppController,
              label: 'Support WhatsApp',
              icon: Icons.chat_bubble_outline,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _minVersionController,
                    label: 'Min App Version',
                    icon: Icons.system_update_alt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _latestVersionController,
                    label: 'Latest Version',
                    icon: Icons.new_releases_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Platform Settings Card ────────────────────────────────────────────────
  Widget _buildPlatformSettingsCard() {
    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardTitle(
              icon: Icons.monetization_on_outlined,
              label: 'Platform Fees',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _defaultCommissionController,
              label: 'Default Commission (%)',
              icon: Icons.percent,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _minOrderController,
              label: 'Minimum Order Amount (Rs)',
              icon: Icons.shopping_bag_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _deliveryFeeController,
              label: 'Default Delivery Fee (Rs)',
              icon: Icons.delivery_dining_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _taxRateController,
              label: 'Tax Rate (e.g. 0.05)',
              icon: Icons.receipt_long_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle Settings Card ──────────────────────────────────────────────────
  Widget _buildToggleSettingsCard() {
    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardTitle(
              icon: Icons.toggle_on_outlined,
              label: 'Platform Controls',
            ),
            const SizedBox(height: 8),
            _buildToggleTile(
              title: 'Accept Orders',
              subtitle: 'Allow customers to place new orders',
              value: _ordersEnabled,
              onChanged: (v) => setState(() => _ordersEnabled = v),
              activeColor: Colors.green,
            ),
            _buildToggleTile(
              title: 'Push Notifications',
              subtitle: 'Send FCM notifications to users and riders',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              activeColor: Colors.blue,
            ),
            _buildToggleTile(
              title: 'Maintenance Mode',
              subtitle: 'Temporarily disable the app for all users',
              value: _maintenanceMode,
              onChanged: (v) => setState(() => _maintenanceMode = v),
              activeColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // ── Danger Zone Card ──────────────────────────────────────────────────────
  Widget _buildDangerZoneCard() {
    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardTitle(
              icon: Icons.warning_amber_rounded,
              label: 'Danger Zone',
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear All Orders'),
                  onPressed: _showClearOrdersDialog,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                  onPressed: _showResetDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
          onPressed: _isSaving ? null : _saveSettings,
        ),
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────

  Widget _buildCardTitle({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtle,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showClearOrdersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Clear All Orders?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all order records. This action cannot be undone.',
          style: TextStyle(color: AppColors.subtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.subtle)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestoreService.clearAllOrders();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All orders cleared successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear orders: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Reset to Defaults?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'All settings will be restored to factory defaults.',
          style: TextStyle(color: AppColors.subtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.subtle)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                final configProvider = Provider.of<ConfigProvider>(context, listen: false);
                await configProvider.resetToDefaults();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() {
                    final config = configProvider.config!;
                    _appNameController.text = config.appName;
                    _supportEmailController.text = config.supportEmail;
                    _supportPhoneController.text = config.supportPhone;
                    _supportWhatsAppController.text = config.supportWhatsApp;
                    _defaultCommissionController.text = config.defaultCommission.toString();
                    _minOrderController.text = config.minOrderAmount.toString();
                    _deliveryFeeController.text = config.baseDeliveryFee.toString();
                    _minVersionController.text = config.minVersion;
                    _latestVersionController.text = config.latestVersion;
                    _taxRateController.text = config.taxRate.toString();
                    _maintenanceMode = config.maintenanceMode;
                    _ordersEnabled = config.ordersEnabled;
                    _notificationsEnabled = config.notificationsEnabled;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to defaults')),
                  );
                }
              } catch (e) {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reset: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child:
                const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
