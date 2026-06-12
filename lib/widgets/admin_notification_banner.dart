import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AdminNotificationBanner extends StatefulWidget {
  final int newOrdersCount;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const AdminNotificationBanner({
    super.key,
    required this.newOrdersCount,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<AdminNotificationBanner> createState() => _AdminNotificationBannerState();
}

class _AdminNotificationBannerState extends State<AdminNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start below screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    if (widget.newOrdersCount > 0) {
      _showBanner();
    }
  }

  @override
  void didUpdateWidget(AdminNotificationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newOrdersCount > 0 && oldWidget.newOrdersCount == 0) {
      _showBanner();
    } else if (widget.newOrdersCount == 0 && oldWidget.newOrdersCount > 0) {
      _hideBanner();
    }
  }

  void _showBanner() {
    _hideTimer?.cancel();
    _controller.forward();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      _hideBanner();
    });
  }

  void _hideBanner() {
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newOrdersCount == 0 && !_controller.isAnimating && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.newOrdersCount} New Order${widget.newOrdersCount > 1 ? 's' : ''} Received',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Tap to view and manage orders',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
