import 'package:flutter/material.dart';
import 'help_center_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushEnabled = true;
  bool smsEnabled = false;
  bool emailEnabled = true;
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.text : Colors.black87;
    final subtitleColor = isDark ? AppColors.subtle : Colors.grey.shade600;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
      body: SafeArea(
        top: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                // Sticky header
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: (isDark ? AppColors.background : AppColors.backgroundLight).withValues(alpha: 0.8),
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.arrow_back, color: primary),
                            ),
                          ),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Text('EN', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('/', style: TextStyle(color: isDark ? AppColors.muted : Colors.grey)),
                                const SizedBox(width: 2),
                                Text('UR', style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  toolbarHeight: 70,
                  automaticallyImplyLeading: false,
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),

                      // Profile section
                      _buildProfileSection(context),

                      const SizedBox(height: 24),

                      // Account Settings group
                      _buildSectionHeader('Account Settings'),
                      const SizedBox(height: 8),
                      _buildAccountSettings(context),

                      const SizedBox(height: 24),

                      // Notifications group
                      _buildSectionHeader('Notifications'),
                      const SizedBox(height: 8),
                      _buildNotifications(context),

                      const SizedBox(height: 24),

                      // App Preferences group
                      _buildSectionHeader('App Preferences'),
                      const SizedBox(height: 8),
                      _buildAppPreferences(context),

                      const SizedBox(height: 24),

                      // Support & About group
                      _buildSectionHeader('Support & About'),
                      const SizedBox(height: 8),
                      _buildSupportAbout(context),

                      const SizedBox(height: 24),

                      // Danger action
                      _buildDangerAction(context),

                      const SizedBox(height: 120), // space for bottom nav
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.local_pizza, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        color: (isDark ? AppColors.card : Colors.white).withValues(alpha: 0.9),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', selected: false),
              _buildNavItem(Icons.receipt_long, 'Orders', selected: false),
              const SizedBox(width: 38),
              _buildNavItem(Icons.shopping_cart, 'Cart', selected: false),
              _buildNavItem(Icons.settings, 'Settings', selected: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.card2 : Colors.white, width: 4),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.2))],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDmO1x9kIu24e_gCS2nu2crD7mufDKSmqWGctM8Z5blWkSkKYzJbLStw8lrSzQAnMWmCHnqH40V-MVeO24qKb_QZbcGUx7VQQZ77siMBNRRbtrCf490Af6v0Vq256Rxv8zdoSDkJMkXdHTcWpEKVy432syRp1VOfcTYW3JCi8dY45Kg_xvQnrk_zk0IHBtIK-HekGqke2x8CZ4MvON5yHrBUhoKDj0JEy1ZkaHN-KtEgdG6nNogg9ZF5UttUIsCk1WdgiB1C0giFMeZ',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 48, color: isDark ? AppColors.subtle : Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.background : Colors.white, width: 4),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'John Vehari',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.text : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'john.doe@pizzahub.com',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.subtle : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: AppColors.subtle,
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade100),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.1))],
      ),
      child: Column(
        children: [
          _buildAccountTile(Icons.person, 'Profile Information', context),
          _buildAccountTile(Icons.lock, 'Password & Security', context),
          _buildAccountTile(
            Icons.location_on,
            'Saved Addresses',
            context,
            isPrimary: true,
            showArrowForward: true,
          ),
          _buildAccountTile(Icons.payment, 'Payment Methods', context, isLast: true),
        ],
      ),
    );
  }

  Widget _buildAccountTile(IconData icon, String label, BuildContext context,
      {bool isLast = false, bool isPrimary = false, bool showArrowForward = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final color = isPrimary ? primary : (isDark ? AppColors.text : Colors.black87);
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? primary : (isDark ? AppColors.subtle : Colors.black54), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (showArrowForward)
              Icon(Icons.arrow_forward, color: primary, size: 20)
            else
              Icon(Icons.chevron_right, color: isDark ? AppColors.muted : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade100),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.1))],
      ),
      child: Column(
        children: [
          _buildToggleTile(
            Icons.notifications_active,
            'Push Notifications',
            pushEnabled,
            (val) => setState(() => pushEnabled = val),
          ),
          _buildToggleTile(
            Icons.sms,
            'SMS Alerts',
            smsEnabled,
            (val) => setState(() => smsEnabled = val),
          ),
          _buildToggleTile(
            Icons.mail,
            'Email Updates',
            emailEnabled,
            (val) => setState(() => emailEnabled = val),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String label, bool value, ValueChanged<bool> onChanged, {bool isLast = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppColors.subtle : Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.text : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: primary.withValues(alpha: 0.3),
            activeThumbColor: primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade100),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.1))],
      ),
      child: Column(
        children: [
          _buildPreferenceTile(
            Icons.language,
            'Language',
            trailing: Text('English (US)', style: TextStyle(color: isDark ? AppColors.subtle : Colors.grey.shade600)),
            showChevron: true,
          ),
          _buildPreferenceTile(
            Icons.delete_sweep,
            'Clear Cache',
            trailing: Text('124 MB', style: TextStyle(color: isDark ? AppColors.subtle : Colors.grey.shade600)),
            isLast: true,
            onTap: () {
              // Clear cache logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(IconData icon, String label, {Widget? trailing, bool showChevron = false, bool isLast = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.subtle : Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.text : Colors.black87,
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: isDark ? AppColors.muted : Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupportAbout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade100),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.1))],
      ),
      child: Column(
        children: [
          _buildSupportTile(
            Icons.help, 
            'Help Center', 
            trailing: Icon(Icons.open_in_new, size: 18, color: isDark ? AppColors.muted : Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
              );
            },
          ),
          _buildSupportTile(Icons.description, 'Terms of Service', showChevron: true),
          _buildSupportTile(Icons.privacy_tip, 'Privacy Policy', showChevron: true),
          _buildVersionTile(),
        ],
      ),
    );
  }

  Widget _buildSupportTile(IconData icon, String label, {Widget? trailing, bool showChevron = false, bool isLast = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: isDark ? AppColors.border : primary.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.subtle : Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.text : Colors.black87,
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
            if (showChevron) Icon(Icons.chevron_right, color: isDark ? AppColors.muted : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(Icons.info, color: isDark ? AppColors.subtle : Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'App Version',
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.text : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'v2.4.0-stable',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerAction(BuildContext context) {
    final primary = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(context, authProvider),
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary.withValues(alpha: 0.2), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: isDark ? AppColors.card : Theme.of(context).colorScheme.surface,
          ),
          child: const Text(
            'Deactivate Account',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pizza O Clock © 2024',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            color: isDark ? AppColors.muted : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AppAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?", style: TextStyle(color: AppColors.subtle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout(context);
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
              }
            },
            child: const Text("Logout", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {required bool selected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final color = selected
        ? primary
        : (isDark ? AppColors.subtle : Colors.grey.shade400);
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


