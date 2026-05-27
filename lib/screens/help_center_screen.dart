import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/route_names.dart';
import '../../core/constants/app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final textColor = isDark ? AppColors.text : Colors.black87;
    final subtitleColor = isDark ? AppColors.subtle : Colors.grey.shade600;
    final borderColor = isDark ? AppColors.border : Colors.grey.shade200;

    return Scaffold(
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
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.arrow_back, color: textColor),
                            ),
                          ),
                          Text(
                            'Help Center',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.card : Colors.white,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.language, size: 16, color: primary),
                                const SizedBox(width: 4),
                                Text(
                                  'EN/UR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.subtle : Colors.grey.shade600,
                                  ),
                                ),
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
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Search bar
                      _buildSearchField(context),

                      const SizedBox(height: 24),

                      // Popular Topics
                      Text(
                        'POPULAR TOPICS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _buildTopicTile(
                            context,
                            icon: Icons.inventory_2,
                            label: 'Order Status',
                            onTap: () {
                              Navigator.pushNamed(context, RouteNames.myOrders);
                            },
                          ),
                          _buildTopicTile(
                            context,
                            icon: Icons.payment,
                            label: 'Payments',
                            onTap: () {},
                          ),
                          _buildTopicTile(
                            context,
                            icon: Icons.keyboard_return,
                            label: 'Refunds',
                            onTap: () {},
                          ),
                          _buildTopicTile(
                            context,
                            icon: Icons.account_circle,
                            label: 'Account',
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // FAQ Section
                      Text(
                        'FREQUENTLY ASKED QUESTIONS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildFaqItem(
                        context,
                        question: 'How to track my order?',
                      ),
                      const SizedBox(height: 8),
                      _buildFaqItem(
                        context,
                        question: 'Can I cancel my order?',
                      ),
                      const SizedBox(height: 8),
                      _buildFaqItem(
                        context,
                        question: 'What are pizza points?',
                      ),
                      const SizedBox(height: 8),
                      _buildFaqItem(
                        context,
                        question: 'Delivery areas in Vehari',
                      ),

                      const SizedBox(height: 24),

                      // Contact Support
                      _buildContactCard(context),

                      const SizedBox(height: 100), // space for bottom nav
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final borderColor = isDark ? AppColors.border : Colors.grey.shade200;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for help...',
          hintStyle: TextStyle(color: isDark ? AppColors.subtle : Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: isDark ? AppColors.text : Colors.black87),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card.withValues(alpha: 0.4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.text.withValues(alpha: 0.8) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, {required String question}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.text.withValues(alpha: 0.8) : Colors.grey.shade700,
            ),
          ),
          trailing: Icon(
            Icons.add,
            color: isDark ? AppColors.subtle : Colors.grey.shade500,
          ),
          children: [
            Text(
              'This is a sample answer to the question. In a real app, this would contain helpful information for the user.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.subtle : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.border : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.support_agent, color: primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Still need help?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.text : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is available 24/7 to assist with your cravings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.subtle : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final Uri whatsappUri = Uri.parse("https://wa.me/923000000000");
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not launch WhatsApp")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Us'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final Uri phoneUri = Uri.parse("tel:+923000000000");
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not launch dialer")),
                    );
                  }
                }
              },
              icon: Icon(Icons.call, color: primary),
              label: Text(
                'Call Support',
                style: TextStyle(color: isDark ? AppColors.text : Colors.black87),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.text : Colors.black87,
                side: BorderSide(color: isDark ? AppColors.border : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.card : Colors.white).withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: primary.withValues(alpha: 0.1))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, Icons.home, 'Home', selected: false, onTap: () {
            Navigator.pushReplacementNamed(context, RouteNames.home);
          }),
          _buildNavItem(context, Icons.shopping_bag, 'Orders', selected: false, onTap: () {
            Navigator.pushNamed(context, RouteNames.myOrders);
          }),
          _buildNavItem(context, Icons.stars, 'Rewards', selected: false, onTap: () {}),
          _buildNavItem(context, Icons.help, 'Help', selected: true, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, {required bool selected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary;
    final color = selected
        ? primary
        : (isDark ? AppColors.subtle : Colors.grey.shade400);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


