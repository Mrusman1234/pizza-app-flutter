import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/invitation_model.dart';
import '../services/restaurant_admin_service.dart';
import '../routes/route_names.dart';

class AcceptInvitationScreen extends StatefulWidget {
  final String? token;
  const AcceptInvitationScreen({super.key, this.token});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final _service = RestaurantAdminService();
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  InvitationModel? _invitation;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInvitation();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInvitation() async {
    final String? token = widget.token ?? Uri.base.queryParameters['token'];
    
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Invalid invitation link. No token found.';
        _isLoading = false;
      });
      return;
    }

    try {
      final invite = await _service.getInvitationByToken(token);
      if (invite == null) {
        _error = 'Invitation not found or has been deleted.';
      } else if (invite.status != 'pending') {
        _error = 'This invitation has already been accepted.';
      } else if (invite.isExpired) {
        _error = 'This invitation has expired. Please ask for a new one.';
      }
      
      setState(() {
        _invitation = invite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error fetching invitation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _accept() async {
    if (!_formKey.currentState!.validate()) return;
    if (_invitation == null) return;

    setState(() => _isProcessing = true);
    final String token = widget.token ?? Uri.base.queryParameters['token']!;

    try {
      await _service.acceptInvitation(
        token: token,
        password: _passwordCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account activated successfully! Please login.'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, RouteNames.adminLogin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, 
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Activate Admin Account',
                  style: TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Set up your password to join Pizza Hub Vehari',
                  style: TextStyle(color: AppColors.subtle, fontSize: 14)),
              const SizedBox(height: 40),

              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else if (_error != null)
                _buildErrorState()
              else
                _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        Text(_error!, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.card),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Name', _invitation!.name),
          const SizedBox(height: 12),
          _infoRow('Email', _invitation!.email),
          const SizedBox(height: 12),
          _infoRow('Restaurant', _invitation!.assignedRestaurantName),
          const SizedBox(height: 32),
          
          const Text('Create Password', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: Colors.white),
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            decoration: _inputDecoration('Password', Icons.lock_outline_rounded),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: Colors.white),
            validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
            decoration: _inputDecoration('Confirm Password', Icons.lock_outline_rounded),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing 
                ? const SizedBox(width: 24, height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Activate My Account', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 100, 
            child: Text(label, style: TextStyle(color: AppColors.subtle, fontSize: 13))),
        Expanded(child: Text(value, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.subtle),
      prefixIcon: Icon(icon, color: AppColors.subtle, size: 20),
      suffixIcon: label == 'Password' ? IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.subtle),
        onPressed: () => setState(() => _obscure = !_obscure),
      ) : null,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppColors.primary, width: 1)),
    );
  }
}
