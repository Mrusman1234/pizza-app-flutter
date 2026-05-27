import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _selectedMethod = 'Visa Card';

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
    });
    
    // If we want to return the selection to the previous screen (e.g. Checkout)
    // we can check if it's pop-able with a result.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method selected as primary payment method'),
        backgroundColor: const Color(0xFFec5b13),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    // Give a small delay for the user to see the selection before popping
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, method);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFFec5b13);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, primary, textColor, borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Digital Wallets', subTextColor),
                    const SizedBox(height: 16),
                    _buildPaymentCard(
                      'EasyPaisa',
                      '0300 **** 567',
                      '',
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Easypaisa_logo.png/640px-Easypaisa_logo.png',
                      isDark,
                      primary,
                      textColor,
                      subTextColor,
                      cardColor,
                      borderColor,
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentCard(
                      'JazzCash',
                      '0301 **** 123',
                      '',
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/JazzCash_logo.png/1200px-JazzCash_logo.png',
                      isDark,
                      primary,
                      textColor,
                      subTextColor,
                      cardColor,
                      borderColor,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Cards', subTextColor),
                    const SizedBox(height: 16),
                    _buildPaymentCard(
                      'Visa Card',
                      '**** **** **** 4242',
                      '04/26',
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/2560px-Visa_Inc._logo.svg.png',
                      isDark,
                      primary,
                      textColor,
                      subTextColor,
                      cardColor,
                      borderColor,
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentCard(
                      'Mastercard',
                      '**** **** **** 8888',
                      '12/24',
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png',
                      isDark,
                      primary,
                      textColor,
                      subTextColor,
                      cardColor,
                      borderColor,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Other Methods', subTextColor),
                    const SizedBox(height: 16),
                    _buildPaymentCard(
                      'PayPal',
                      'johndoe@email.com',
                      '',
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/1200px-PayPal.svg.png',
                      isDark,
                      primary,
                      textColor,
                      subTextColor,
                      cardColor,
                      borderColor,
                    ),
                    const SizedBox(height: 32),
                    _buildAddNewButton(primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primary, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              'EN/UR',
              style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subTextColor) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: subTextColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPaymentCard(
    String name,
    String detail,
    String expiry,
    String logoUrl,
    bool isDark,
    Color primary,
    Color textColor,
    Color subTextColor,
    Color cardColor,
    Color borderColor,
  ) {
    bool isSelected = _selectedMethod == name;
    return InkWell(
      onTap: () => _selectMethod(name),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primary.withValues(alpha: 0.5) : borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance_wallet, color: subTextColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (expiry.isNotEmpty)
              Text(
                expiry,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primary : subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton(Color primary) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add New Method feature coming soon!')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Add New Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


