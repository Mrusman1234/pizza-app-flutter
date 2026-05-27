import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'my_orders_screen.dart';
import 'payment_methods_screen.dart';
import 'address_management_screen.dart';
import 'help_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> _logout(BuildContext context) async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.logout(context);
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
      }
    } catch (e) {
      debugPrint("Logout error: $e");
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout from your account?", 
          style: TextStyle(color: AppColors.subtle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            String name = user?.displayName ?? "User";
            String email = user?.email ?? "No Email";
            String photoUrl = user?.photoURL ??
                "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
            String orders = "0";
            String reviews = "0";
            String points = "0";

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['name'] ?? data['fullName'] ?? name;
              email = data['email'] ?? email;
              photoUrl = data['photoUrl'] ?? data['profileImage'] ?? data['avatar'] ?? photoUrl;
              orders = data['orders']?.toString() ?? "0";
              reviews = data['reviews']?.toString() ?? "0";
              points = data['points']?.toString() ?? "0";
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.text),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Text("Profile",
                            style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.text),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// PROFILE CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.card2,
                                backgroundImage: NetworkImage(photoUrl),
                                onBackgroundImageError: (error, stackTrace) {},
                                child: photoUrl.contains('flaticon') || photoUrl.isEmpty
                                    ? const Icon(Icons.person, size: 40, color: AppColors.muted)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                                child: Container(
                                  height: 28, width: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.background, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(name, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: AppColors.subtle, fontSize: 14)),
                      ],
                    ),
                  ),

                  /// STATS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatBox(title: "Orders", value: orders),
                        const SizedBox(width: 12),
                        _StatBox(title: "Reviews", value: reviews),
                        const SizedBox(width: 12),
                        _StatBox(title: "Points", value: points),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// ACTIONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ACCOUNT SETTINGS", style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.receipt_long_outlined,
                          label: "My Orders",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersScreen())),
                        ),
                        _ActionCard(
                          icon: Icons.location_on_outlined,
                          label: "Saved Addresses",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressManagementScreen())),
                        ),
                        _ActionCard(
                          icon: Icons.payment_outlined,
                          label: "Payment Methods",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen())),
                        ),
                        _ActionCard(
                          icon: Icons.notifications_none_outlined,
                          label: "Notifications",
                          onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text("SUPPORT", style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.help_outline,
                          label: "Help Center",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen())),
                        ),
                        _ActionCard(
                          icon: Icons.info_outline,
                          label: "About Pizza O Clock",
                          onTap: () {},
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showLogoutDialog(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text("Logout", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppColors.subtle, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.text, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}


