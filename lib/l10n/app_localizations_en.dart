// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pizza O Clock';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Full Name';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get searchHint => 'Search for pizzas or restaurants...';

  @override
  String get popularPizzas => 'Popular Pizzas';

  @override
  String get nearbyRestaurants => 'Nearby Restaurants';

  @override
  String get cart => 'Your Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';
}
