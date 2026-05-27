import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLanguage = 'EN';

  // Password Rules State
  bool _has8Chars = false;
  bool _hasUppercase = false;
  bool _hasSpecialOrNum = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRules);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final password = _passwordController.text;
    setState(() {
      _has8Chars = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasSpecialOrNum = password.contains(RegExp(r'[0-9_]'));
    });
  }

  void _setLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
    });
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        context,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please login.'),
              backgroundColor: AppColors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, RouteNames.login);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup failed. The email might be in use.'),
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
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Join the hub for the best pizza in Vehari",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtle, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  /// Full Name
                  CustomTextField(
                    controller: _nameController,
                    label: "Full Name",
                    hint: "Enter your full name",
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateName,
                  ),

                  const SizedBox(height: 16),

                  /// Email
                  CustomTextField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "Enter your email",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 16),

                  /// Password
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
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Password Indicators
                  _buildPasswordIndicators(),

                  const SizedBox(height: 16),

                  /// Confirm Password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: "Confirm Password",
                    hint: "Re-enter your password",
                    prefixIcon: Icons.lock_outline,
                    isPassword: _obscureConfirmPassword,
                    validator: (value) {
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Create Button
                  CustomButton(
                    text: AppStrings.signup,
                    onPressed: _handleSignup,
                    isLoading: authProvider.isLoading,
                  ),

                  const SizedBox(height: 30),

                  /// Login link
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: AppStrings.alreadyHaveAccount,
                        style: TextStyle(
                          color: isDark ? AppColors.subtle : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: " "),
                          TextSpan(
                            text: "Login here",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.pushReplacementNamed(context, RouteNames.login),
                          ),
                        ],
                      ),
                    ),
                  )
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
        const SizedBox(height: 6),
        _ruleIndicator("Can include numbers or underscore", _hasSpecialOrNum),
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
}


