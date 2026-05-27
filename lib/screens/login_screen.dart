import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String _selectedLanguage = 'EN';

  // Password Rules State
  bool _has8Chars = false;
  bool _hasUppercase = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRules);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final password = _passwordController.text;
    setState(() {
      _has8Chars = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _setLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context,
      );

      if (mounted) {
        if (success) {
          final user = authProvider.user;
          if (user != null) {
            if (user.role == 'admin') {
              Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
            } else if (user.role == 'rider') {
              Navigator.pushReplacementNamed(context, RouteNames.riderDashboard);
            } else {
              Navigator.pushReplacementNamed(context, RouteNames.home);
            }
          } else {
            Navigator.pushReplacementNamed(context, RouteNames.home);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login failed. Please check your credentials."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final success = await authProvider.googleSignIn(context);

    if (mounted) {
      if (success) {
        final user = authProvider.user;
        if (user != null) {
          if (user.role == 'admin') {
            Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
          } else if (user.role == 'rider') {
            Navigator.pushReplacementNamed(context, RouteNames.riderDashboard);
          } else {
            Navigator.pushReplacementNamed(context, RouteNames.home);
          }
        } else {
          Navigator.pushReplacementNamed(context, RouteNames.home);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Sign-In failed or was cancelled"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.text),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      _buildLanguageSwitcher(),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.local_pizza, color: Colors.white, size: 32),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  const Text(
                    "Welcome Back!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login to order your favorite pizza in Vehari",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtle, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  /// Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "Enter your email",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 20),

                  /// Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "Enter your password",
                    prefixIcon: Icons.lock_outline,
                    isPassword: _obscurePassword,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Password Indicators
                  _buildPasswordIndicators(),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.forgotPassword),
                      child: const Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Login Button
                  CustomButton(
                    text: AppStrings.login,
                    onPressed: _handleLogin,
                    isLoading: authProvider.isLoading,
                  ),

                  const SizedBox(height: 24),

                  _buildDivider(),

                  const SizedBox(height: 24),

                  /// Google Button
                  CustomButton(
                    text: "Continue with Google",
                    onPressed: _signInWithGoogle,
                    isOutlined: true,
                    color: AppColors.border,
                    textColor: AppColors.text,
                  ),

                  const SizedBox(height: 30),

                  /// Signup Row
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.subtle : Colors.grey.shade600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, RouteNames.signup),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Admin Login Link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.adminLogin),
                      child: Text(
                        "Login as Administrator",
                        style: TextStyle(
                          color: AppColors.muted.withValues(alpha: 0.7),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

  Widget _buildLanguageSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _languageOption('EN'),
          _languageOption('UR'),
        ],
      ),
    );
  }

  Widget _languageOption(String lang) {
    bool isSelected = _selectedLanguage == lang;
    return InkWell(
      onTap: () => _setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          lang,
          style: TextStyle(
              color: isSelected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPasswordIndicators() {
    return Column(
      children: [
        _ruleIndicator("At least 8 characters", _has8Chars),
        const SizedBox(height: 6),
        _ruleIndicator("Contains one uppercase letter", _hasUppercase),
      ],
    );
  }

  Widget _ruleIndicator(String text, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: isSatisfied ? AppColors.green : AppColors.muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSatisfied ? AppColors.green : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Or continue with", style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}


