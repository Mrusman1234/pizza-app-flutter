import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // ── Added: controllers so we can read the field values ──
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── ADDED: real validation + Firebase password update ──────────────────────
  bool get _hasMinLength => _newPassController.text.length >= 8;
  bool get _hasSymbol =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(_newPassController.text);
  bool get _hasUppercase => _newPassController.text.contains(RegExp(r'[A-Z]'));

  Future<void> _handleResetPassword() async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('Please fill in both fields.', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }
    if (!_hasMinLength || !_hasSymbol || !_hasUppercase) {
      _showSnack(
        'Password must be 8+ characters, include a symbol and an uppercase letter.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('Session expired. Please sign in again.', isError: true);
        return;
      }
      await user.updatePassword(newPass);
      if (mounted) {
        _showSnack('Password updated successfully!');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'requires-recent-login'
          ? 'For security, please sign out and sign in again before changing your password.'
          : e.message ?? 'Failed to update password.';
      _showSnack(message, isError: true);
    } catch (e) {
      _showSnack('An unexpected error occurred.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFFd3122f);
    final surface = isDark ? const Color(0xFF1e293b) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final backgroundColor =
        isDark ? const Color(0xFF221013) : const Color(0xFFf8f6f6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.arrow_back,
                              color: textColor, size: 24),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'EN/UR',
                          style: TextStyle(
                            color: Color(0xFFd3122f),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Header ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a strong new password for your account to keep your food orders secure.',
                        style: TextStyle(fontSize: 16, color: subtitleColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Lock illustration ─────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline,
                            color: primary, size: 64),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: backgroundColor, width: 4),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Form fields ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildPasswordField(
                        label: 'New Password',
                        controller: _newPassController,
                        obscureText: _obscureNew,
                        onVisibilityToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        isDark: isDark,
                        borderColor: borderColor,
                        surface: surface,
                        // rebuild chips on every keystroke
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'Confirm Password',
                        controller: _confirmPassController,
                        obscureText: _obscureConfirm,
                        onVisibilityToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        isDark: isDark,
                        borderColor: borderColor,
                        surface: surface,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Live requirement chips ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _buildRequirementChip(
                        icon: _hasMinLength
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        label: '8+ characters',
                        isDark: isDark,
                        met: _hasMinLength,
                      ),
                      _buildRequirementChip(
                        icon: _hasSymbol
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        label: '1 symbol',
                        isDark: isDark,
                        met: _hasSymbol,
                      ),
                      _buildRequirementChip(
                        icon: _hasUppercase
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        label: '1 uppercase',
                        isDark: isDark,
                        met: _hasUppercase,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Action button ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                            shadowColor: primary.withValues(alpha: 0.2),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Reset Password',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remembered your password? ',
                            style: TextStyle(
                                color: subtitleColor, fontSize: 14),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required bool isDark,
    required Color borderColor,
    required Color surface,
    ValueChanged<String>? onChanged,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: surface,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(
                  color: isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                onPressed: onVisibilityToggle,
              ),
            ),
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool met,
  }) {
    final color = met
        ? Colors.green
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}