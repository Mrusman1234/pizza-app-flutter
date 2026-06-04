import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ✅ ALL imports fixed — flat screens/ folder (no subfolders)
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/order_tracking_screen.dart';
import '../screens/order_details_screen.dart';
import '../screens/address_management_screen.dart';
import '../screens/add_address_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/restaurants_screen.dart';
import '../screens/restaurant_menu_screen.dart';
import '../screens/pizza_detail_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/customer_management_screen.dart';
import '../screens/rider_management_screen.dart';
import '../screens/promotions_screen.dart';
import '../screens/notifications_manager_screen.dart';
import '../screens/commissions_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/performance_report_screen.dart';
import '../screens/restaurant_report_screen.dart';
import '../screens/super_admin_restaurant_admins_screen.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/admin_login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/rider_dashboard_screen.dart';
import '../screens/restaurant_management_screen.dart';
import '../screens/restaurant_admin_dashboard_screen.dart';
import '../screens/restaurant_admin_orders_screen.dart';
import '../screens/restaurant_admin_menu_screen.dart';
import '../screens/restaurant_admin_audit_logs_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_methods_screen.dart';
import '../screens/order_success_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/store_product_management_screen.dart';
import '../screens/wallet_screen.dart';
import '../models/restaurant_model.dart';
import 'route_names.dart';

class AppRoutes {
  /// ── ROLE & PLATFORM GUARD ───────────────────────────────────────────────
  /// Wraps a builder to check if user has permission to see the screen.
  static Widget _guard(BuildContext context, Widget screen, {bool webOnly = false}) {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    
    // 1. Check platform if required
    if (webOnly && !kIsWeb) {
      debugPrint('🚫 GUARD: Attempted to access web-only route on mobile.');
      return const _AccessDeniedScreen(message: "Admin Panel is only available on Web.");
    }

    // 2. Check auth
    if (!auth.isAuthenticated) {
      debugPrint('🚫 GUARD: User not authenticated.');
      return const LoginScreen();
    }

    return screen;
  }

  static Map<String, WidgetBuilder> get routes => {

    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.adminLogin: (_) => const AdminLoginScreen(),
    RouteNames.forgotPassword: (_) => const ForgotPasswordScreen(),
    RouteNames.signup: (_) => const SignupScreen(),
    RouteNames.home: (_) => const HomeScreen(),
    RouteNames.cart: (_) => const CartScreen(),
    RouteNames.profile: (_) => const ProfileScreen(),
    RouteNames.editProfile: (_) => const EditProfileScreen(),
    RouteNames.checkout: (_) => const CheckoutScreen(),
    RouteNames.myOrders: (_) => const MyOrdersScreen(),
    RouteNames.settings: (_) => const SettingsScreen(),
    RouteNames.helpCenter: (_) => const HelpCenterScreen(),

    RouteNames.orderTracking: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      final orderId = args is String
          ? args
          : (args as Map<String, dynamic>?)?['orderId'] as String? ?? '';
      return OrderTrackingScreen(orderId: orderId);
    },

    RouteNames.orderDetails: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      final orderId = args is String
          ? args
          : (args as Map<String, dynamic>?)?['orderId'] as String?;
      return OrderDetailsScreen(orderId: orderId);
    },

    RouteNames.addressManagement: (_) => const AddressManagementScreen(),
    RouteNames.addAddress: (_) => const AddAddressScreen(),
    RouteNames.notifications: (_) => const NotificationsScreen(),
    RouteNames.restaurants: (_) => const RestaurantsScreen(),

    RouteNames.restaurantDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is RestaurantModel) {
        return RestaurantMenuScreen(
          restaurantId: args.id,
          restaurantName: args.name,
        );
      } else if (args is String) {
        return RestaurantMenuScreen(
          restaurantId: args,
          restaurantName: 'Restaurant',
        );
      }
      return const RestaurantMenuScreen();
    },

    RouteNames.pizzaDetail: (_) => const PizzaDetailScreen(),

    // ✅ Admin routes (Gaurded)
    RouteNames.adminDashboard: (context) => _guard(context, const AdminDashboardScreen(), webOnly: true),
    RouteNames.adminOrders: (context) => _guard(context, const AdminOrdersScreen(), webOnly: true),
    RouteNames.adminCustomers: (context) => _guard(context, const CustomerManagementScreen(), webOnly: true),
    RouteNames.adminStores: (context) => _guard(context, const RestaurantManagementScreen(), webOnly: true),
    RouteNames.adminRiders: (context) => _guard(context, const RiderManagementScreen(), webOnly: true),
    RouteNames.adminPromotions: (context) => _guard(context, const PromotionsManagementScreen(), webOnly: true),
    RouteNames.adminNotifications: (context) => _guard(context, const NotificationsManagerScreen(), webOnly: true),
    RouteNames.adminCommissions: (context) => _guard(context, const CommissionsScreen(), webOnly: true),
    RouteNames.adminAnalytics: (context) => _guard(context, const AnalyticsScreen(), webOnly: true),
    RouteNames.adminPerformance: (context) => _guard(context, const PerformanceReportScreen(), webOnly: true),
    RouteNames.adminRestaurantReport: (context) => _guard(context, const RestaurantReportScreen(), webOnly: true),
    RouteNames.adminRestaurantAdmins: (context) => _guard(context, const SuperAdminRestaurantAdminsScreen(), webOnly: true),
    RouteNames.superAdminRestaurantAdmins: (context) => _guard(context, const SuperAdminRestaurantAdminsScreen(), webOnly: true),
    RouteNames.adminSettings: (context) => _guard(context, const AdminSettingsScreen(), webOnly: true),
    RouteNames.adminStoreProducts: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return _guard(context, StoreProductManagementScreen(
        restaurantId: args['id'],
        restaurantName: args['name'],
      ), webOnly: true);
    },

    // ✅ Restaurant Admin routes
    RouteNames.restaurantAdminDashboard: (context) => _guard(context, const RestaurantAdminDashboardScreen(), webOnly: true),
    RouteNames.restaurantAdminOrders: (context) => _guard(context, const RestaurantAdminOrdersScreen(), webOnly: true),
    RouteNames.restaurantAdminMenu: (context) => _guard(context, const RestaurantAdminMenuScreen(), webOnly: true),
    RouteNames.restaurantAdminAuditLogs: (context) => _guard(context, const RestaurantAdminAuditLogsScreen(), webOnly: true),

    // ✅ Rider routes
    RouteNames.riderDashboard: (context) => _guard(context, const RiderDashboardScreen()),

    // ✅ Payment routes
    RouteNames.payment: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PaymentScreen(
        amount: args['amount'],
        orderId: args['orderId'],
      );
    },
    RouteNames.paymentMethods: (_) => const PaymentMethodsScreen(),
    RouteNames.orderSuccess: (context) {
      final txnRef = ModalRoute.of(context)!.settings.arguments as String?;
      return OrderSuccessScreen(txnRef: txnRef);
    },
    RouteNames.chat: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ChatScreen(
        orderId: args['orderId'],
        otherUserName: args['otherUserName'],
      );
    },
    RouteNames.wallet: (context) => const WalletScreen(),
  };
}

class _AccessDeniedScreen extends StatelessWidget {
  final String message;
  const _AccessDeniedScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text("Access Restricted", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
                child: const Text("Return to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
