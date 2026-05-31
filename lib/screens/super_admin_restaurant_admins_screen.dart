import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/restaurant_admin_model.dart';
import '../providers/auth_provider.dart';
import '../services/restaurant_admin_service.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_sidebar.dart';

class SuperAdminRestaurantAdminsScreen extends StatefulWidget {
  const SuperAdminRestaurantAdminsScreen({super.key});

  @override
  State<SuperAdminRestaurantAdminsScreen> createState() =>
      _SuperAdminRestaurantAdminsScreenState();
}

class _SuperAdminRestaurantAdminsScreenState
    extends State<SuperAdminRestaurantAdminsScreen> {
  final _service = RestaurantAdminService();
  final _firestoreService = FirestoreService();
  bool _showForm = false;

  // ── Create form controllers ───────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isCreating = false;
  String? _selectedRestaurantId;
  String? _selectedRestaurantName;
  List<String> _permissions = List.from(RestaurantAdminModel.defaultPermissions);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a restaurant'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isCreating = true);
    final superAdminId = context.read<AppAuthProvider>().user?.uid;

    try {
      await _service.createRestaurantAdmin(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        restaurantId: _selectedRestaurantId!,
        restaurantName: _selectedRestaurantName!,
        permissions: _permissions,
        superAdminId: superAdminId,
      );

      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      setState(() {
        _selectedRestaurantId = null;
        _selectedRestaurantName = null;
        _showForm = false;
        _permissions = List.from(RestaurantAdminModel.defaultPermissions);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restaurant admin created'),
              backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _deactivate(RestaurantAdminModel admin) async {
    final superAdminId = context.read<AppAuthProvider>().user?.uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Deactivate ${admin.name}?',
            style: const TextStyle(color: AppColors.text, fontSize: 16)),
        content: Text(
          '${admin.email} will lose access to ${admin.assignedRestaurantName}.',
          style: const TextStyle(color: AppColors.subtle, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.subtle))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deactivateRestaurantAdmin(admin.uid,
        superAdminId: superAdminId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeItem: 'Res. Admins'),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: const Text('Restaurant Admins',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _showForm ? Icons.close_rounded : Icons.person_add_rounded,
                        color: AppColors.primary,
                      ),
                      tooltip: _showForm ? 'Close form' : 'Create admin',
                      onPressed: () => setState(() => _showForm = !_showForm),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                if (_showForm) 
                  SingleChildScrollView(child: _buildCreateForm()),
                Expanded(child: _buildAdminList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New restaurant admin',
                style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 14),
            _formField('Full name', _nameCtrl, Icons.person_rounded),
            const SizedBox(height: 10),
            _formField('Email', _emailCtrl, Icons.email_rounded,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _formField('Password', _passwordCtrl, Icons.lock_rounded,
                obscure: true),
            const SizedBox(height: 10),
            // Restaurant picker
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getRestaurants(),
              builder: (context, snap) {
                final restaurants = snap.data ?? [];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    value: _selectedRestaurantId,
                    hint: const Text('Select restaurant',
                        style: TextStyle(
                            color: AppColors.subtle, fontSize: 13)),
                    underline: const SizedBox(),
                    items: restaurants
                        .map((r) => DropdownMenuItem<String>(
                              value: r['id'] as String,
                              child: Text(r['name'] as String? ?? '',
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (id) {
                      final r = restaurants.firstWhere(
                          (r) => r['id'] == id,
                          orElse: () => {});
                      setState(() {
                        _selectedRestaurantId = id;
                        _selectedRestaurantName = r['name'] as String?;
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Permissions checkboxes
            const Text('Permissions',
                style: TextStyle(
                    color: AppColors.subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['orders', 'menu', 'stats'].map((perm) {
                final checked = _permissions.contains(perm);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (checked) {
                        _permissions.remove(perm);
                      } else {
                        _permissions.add(perm);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: checked
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.card2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: checked
                            ? AppColors.primary
                            : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          checked
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: checked
                              ? AppColors.primary
                              : AppColors.subtle,
                        ),
                        const SizedBox(width: 4),
                        Text(perm,
                            style: TextStyle(
                              color: checked
                                  ? AppColors.primary
                                  : AppColors.subtle,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Admin',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon,
      {bool obscure = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure && _obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.text, fontSize: 13),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.subtle, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.subtle, size: 18),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.subtle,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: AppColors.card2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildAdminList() {
    return StreamBuilder<List<RestaurantAdminModel>>(
      stream: _service.getAllRestaurantAdmins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline_rounded,
                    color: AppColors.subtle, size: 48),
                const SizedBox(height: 12),
                const Text('No restaurant admins yet',
                    style: TextStyle(color: AppColors.subtle)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.add_rounded,
                      color: AppColors.primary, size: 18),
                  label: const Text('Create one',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: admins.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _buildAdminCard(admins[i]),
        );
      },
    );
  }

  Widget _buildAdminCard(RestaurantAdminModel admin) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Opacity(
        opacity: admin.isActive ? 1.0 : 0.5,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: admin.isActive
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.muted.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  admin.name.isNotEmpty
                      ? admin.name[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: admin.isActive
                        ? AppColors.primary
                        : AppColors.subtle,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(admin.name,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(admin.email,
                      style: const TextStyle(
                          color: AppColors.subtle, fontSize: 11)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.store_rounded,
                          size: 11, color: AppColors.subtle),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(admin.assignedRestaurantName,
                            style: const TextStyle(
                                color: AppColors.subtle, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: admin.permissions
                        .map((p) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(p,
                                  style: const TextStyle(
                                      color: AppColors.subtle,
                                      fontSize: 10)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: admin.isActive
                        ? AppColors.green.withValues(alpha: 0.15)
                        : Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color:
                          admin.isActive ? AppColors.green : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (admin.isActive) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _deactivate(admin),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            width: 0.5),
                      ),
                      child: const Text('Deactivate',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 10)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
