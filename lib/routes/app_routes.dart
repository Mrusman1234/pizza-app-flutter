import 'package:flutter/material.dart';

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
import '../screens/admin_settings_screen.dart';
import '../screens/admin_login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/rider_dashboard_screen.dart';
import '../screens/restaurant_management_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/order_success_screen.dart';
import '../models/restaurant_model.dart';
import 'route_names.dart';

class AppRoutes {
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

    // ✅ Admin routes
    RouteNames.adminDashboard: (_) => const AdminDashboardScreen(),
    RouteNames.adminOrders: (_) => const AdminOrdersScreen(),
    RouteNames.adminCustomers: (_) => const CustomerManagementScreen(),
    RouteNames.adminStores: (_) => const RestaurantManagementScreen(),
    RouteNames.adminRiders: (_) => const RiderManagementScreen(),
    RouteNames.adminPromotions: (_) => const PromotionsManagementScreen(),
    RouteNames.adminNotifications: (_) => const NotificationsManagerScreen(),
    RouteNames.adminCommissions: (_) => const CommissionsScreen(),
    RouteNames.adminAnalytics: (_) => const AnalyticsScreen(),
    RouteNames.adminPerformance: (_) => const PerformanceReportScreen(),
    RouteNames.adminRestaurantReport: (_) => const RestaurantReportScreen(),
    RouteNames.adminSettings: (_) => const AdminSettingsScreen(),

    // ✅ Rider routes
    RouteNames.riderDashboard: (_) => const RiderDashboardScreen(),

    // ✅ Payment routes
    RouteNames.payment: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PaymentScreen(
        amount: args['amount'],
        orderId: args['orderId'],
      );
    },
    RouteNames.orderSuccess: (context) {
      final txnRef = ModalRoute.of(context)!.settings.arguments as String?;
      return OrderSuccessScreen(txnRef: txnRef);
    },
  };
}
