import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminTokenController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminTokenController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleAdminLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      
      debugPrint('🚀 Admin Login Attempt: ${_emailController.text.trim()}');

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context,
      );

      debugPrint('🔐 Firebase Auth Success: $success');

      if (mounted) {
        if (success) {
          final user = authProvider.user;
          debugPrint('📄 Firestore User Document: ${user != null ? "Found" : "Not Found"}');
          debugPrint('👤 Role Found: ${user?.role}');

          if (user != null && user.role == 'admin') {
            debugPrint('✅ Access Granted. Navigating to Dashboard...');
            Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
          } else {
            debugPrint('❌ Access Denied: User role is "${user?.role}"');
            await authProvider.logout(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Access Denied: You do not have administrator privileges."),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } else {
          debugPrint('❌ Login Failed: Check credentials or connectivity.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Admin Login failed. Please check your credentials."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Admin Portal",
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Administrator Login",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your credentials to access the management dashboard",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtle, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    controller: _emailController,
                    label: "Admin Email",
                    hint: "admin@pizzahub.com",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "••••••••",
                    prefixIcon: Icons.lock_outline,
                    isPassword: _obscurePassword,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Optional: Security Token Field for extra admin security
                  CustomTextField(
                    controller: _adminTokenController,
                    label: "Security Token (Optional)",
                    hint: "Enter 6-digit code",
                    prefixIcon: Icons.security,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: "Access Dashboard",
                    onPressed: _handleAdminLogin,
                    isLoading: authProvider.isLoading,
                  ),

                  const SizedBox(height: 24),
                  
                  const Center(
                    child: Text(
                      "Secured by Enterprise Shield",
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


