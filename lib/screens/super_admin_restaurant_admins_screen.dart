import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/restaurant_admin_model.dart';
import '../models/invitation_model.dart';
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
  bool _isCreating = false;
  String? _selectedRestaurantId;
  String? _selectedRestaurantName;
  List<String> _permissions = List.from(RestaurantAdminModel.defaultPermissions);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    debugPrint('🚀 [DEBUG] _sendInvite button clicked');
    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ [DEBUG] Form validation failed');
      return;
    }
    if (_selectedRestaurantId == null) {
      debugPrint('⚠️ [DEBUG] No restaurant selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a restaurant'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isCreating = true);
    final superAdminId = context.read<AppAuthProvider>().user?.uid;
    debugPrint('🔍 [DEBUG] Current Super Admin ID: $superAdminId');

    try {
      debugPrint('⏳ [DEBUG] Calling _service.sendInvitation...');
      await _service.sendInvitation(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        restaurantId: _selectedRestaurantId!,
        restaurantName: _selectedRestaurantName!,
        permissions: _permissions,
        superAdminId: superAdminId,
      );
      debugPrint('✅ [DEBUG] _service.sendInvitation returned successfully');

      _nameCtrl.clear();
      _emailCtrl.clear();
      setState(() {
        _selectedRestaurantId = null;
        _selectedRestaurantName = null;
        _showForm = false;
        _permissions = List.from(RestaurantAdminModel.defaultPermissions);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invitation email sent'),
              backgroundColor: AppColors.green),
        );
      }
    } catch (e, stack) {
      debugPrint('❌ [DEBUG] Error in _sendInvite: $e');
      debugPrint('📜 [DEBUG] Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send invitation: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      debugPrint('🔄 [DEBUG] _sendInvite flow completed, resetting loading state');
      if (mounted) {
        setState(() => _isCreating = false);
      }
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

  Widget _buildErrorWidget(String title, Object? error) {
    debugPrint('🔥 [UI_ERROR] $title: $error');
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(error.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ...
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
              runSpacing: 8,
              children: [
                'orders',
                'menu',
                'stats',
                'notifications',
                'analytics',
                'commissions'
              ].map((perm) {
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
                onPressed: _isCreating ? null : _sendInvite,
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
                    : const Text('Send Invitation',
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
      obscureText: obscure && obscure,
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
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.subtle,
                  size: 18,
                ),
                onPressed: () => setState(() => obscure = !obscure),
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
    return Column(
      children: [
        // ── PENDING INVITATIONS ─────────────────────────────────────────────
        StreamBuilder<List<InvitationModel>>(
          stream: _service.getPendingInvitations(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorWidget('Invitations Error', snapshot.error);
            }
            final invites = snapshot.data ?? [];
            if (invites.isEmpty && snapshot.connectionState == ConnectionState.active) {
              return const SizedBox.shrink();
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Pending Invitations',
                    style: TextStyle(
                        color: AppColors.subtle,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ),
                ...invites.map((invite) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildInviteCard(invite),
                    )),
                const Divider(height: 32, indent: 16, endIndent: 16),
              ],
            );
          },
        ),

        // ── ACTIVE ADMINS ───────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<RestaurantAdminModel>>(
            stream: _service.getAllRestaurantAdmins(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              final admins = snapshot.data ?? [];
              
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (admins.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Active Admins',
                          style: TextStyle(
                              color: AppColors.subtle,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ),
                  if (admins.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Icon(Icons.people_outline_rounded,
                              color: AppColors.subtle, size: 48),
                          const SizedBox(height: 12),
                          const Text('No restaurant admins yet',
                              style: TextStyle(color: AppColors.subtle)),
                        ],
                      ),
                    )
                  else
                    ...admins.map((admin) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildAdminCard(admin),
                        )),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCard(InvitationModel invite) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.mail_outline_rounded, color: AppColors.amber, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.name,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(invite.email,
                    style: const TextStyle(
                        color: AppColors.subtle, fontSize: 11)),
                const SizedBox(height: 3),
                Text('Invited to ${invite.assignedRestaurantName}',
                    style: const TextStyle(
                        color: AppColors.subtle, fontSize: 10)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (invite.status == 'sent' ? AppColors.green : AppColors.amber).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(invite.status == 'sent' ? 'Sent' : 'Pending',
                    style: TextStyle(
                        color: invite.status == 'sent' ? AppColors.green : AppColors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final String baseUrl = Uri.base.origin;
                  final String link = '$baseUrl/#/accept-invitation?token=${invite.id}';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation link copied to clipboard')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 0.5),
                  ),
                  child: const Text('Copy Link',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
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
