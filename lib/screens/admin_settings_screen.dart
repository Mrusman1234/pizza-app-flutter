import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/admin_sidebar.dart';
import '../../routes/route_names.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          key: isMobile ? GlobalKey<ScaffoldState>() : null,
          backgroundColor: AppColors.background,
          drawer: isMobile ? const Drawer(child: AdminSidebar(activeItem: 'Settings')) : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.card,
                  title: const Text("Settings", style: TextStyle(color: Colors.white, fontSize: 18)),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const AdminSidebar(activeItem: 'Settings'),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    if (!isMobile)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Settings',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your administrative preferences and system configuration',
                              style: TextStyle(fontSize: 14, color: AppColors.subtle),
                            ),
                          ],
                        ),
                      ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Application Preferences'),
                                const SizedBox(height: 16),
                                _buildSettingTile(
                                  isMobile: isMobile,
                                  icon: Icons.language_outlined,
                                  title: 'System Language',
                                  subtitle: 'Choose the default language for the dashboard',
                                  trailing: const Text(
                                    'English (US)',
                                    style: TextStyle(color: AppColors.subtle),
                                  ),
                                  onTap: () {
                                    // Language selection logic
                                  },
                                ),
                                
                                const SizedBox(height: 32),
                                _buildSectionHeader('System Management'),
                                const SizedBox(height: 16),
                                _buildSettingTile(
                                  isMobile: isMobile,
                                  icon: Icons.security_outlined,
                                  title: 'Security Logs',
                                  subtitle: 'Review recent administrative actions',
                                  trailing: const Icon(Icons.chevron_right, color: AppColors.subtle),
                                  onTap: () {
                                    // Security logs logic
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildSettingTile(
                                  isMobile: isMobile,
                                  icon: Icons.storage_outlined,
                                  title: 'Database Backups',
                                  subtitle: 'Manage and schedule system backups',
                                  trailing: const Icon(Icons.chevron_right, color: AppColors.subtle),
                                  onTap: () {
                                    // Backup management logic
                                  },
                                ),

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
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        RouteNames.login,
                                        (_) => false,
                                      );
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingTile({
    required bool isMobile,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.subtle, fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }
}


