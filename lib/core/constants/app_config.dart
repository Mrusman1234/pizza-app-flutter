import 'package:flutter/foundation.dart';

/// App Configuration - API Keys and Environment Settings
/// 
/// IMPORTANT: For production, these values should be loaded from:
/// 1. Environment variables (using --dart-define)
/// 2. Firebase Remote Config
/// 3. Secure key management service
/// 
/// Example build command with dart-define:
/// flutter run --dart-define=MAPS_API_KEY=your_actual_key
class AppConfig {
  // API Keys
  static String get googleMapsApiKey {
    const key = String.fromEnvironment('MAPS_API_KEY');
    if (key.isNotEmpty) return key;
    if (kDebugMode) return 'YOUR_MAPS_API_KEY_HERE';
    throw Exception('MAPS_API_KEY not set');
  }

  static Map<String, String> get jazzCashConfig {
    return {
      'merchantId': const String.fromEnvironment('JC_MERCHANT_ID', defaultValue: ''),
      'password': const String.fromEnvironment('JC_PASSWORD', defaultValue: ''),
      'integritySalt': const String.fromEnvironment('JC_SALT', defaultValue: ''),
      'sandboxUrl': 'https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction',
      'productionUrl': 'https://payments.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction',
    };
  }

  static Map<String, String> get easyPaisaConfig {
    return {
      'storeId': const String.fromEnvironment('EP_STORE_ID', defaultValue: ''),
      'hashKey': const String.fromEnvironment('EP_HASH_KEY', defaultValue: ''),
      'sandboxUrl': 'https://easypaystg.easypaisa.com.pk/easypay/Index',
      'productionUrl': 'https://easypay.easypaisa.com.pk/easypay/Index',
    };
  }

  static bool get arePaymentCredentialsConfigured {
    final jc = jazzCashConfig;
    final ep = easyPaisaConfig;
    return jc['merchantId']!.isNotEmpty && ep['storeId']!.isNotEmpty;
  }

  static String get recaptchaSiteKey {
    return const String.fromEnvironment('RECAPTCHA_SITE_KEY', defaultValue: '');
  }

  // Note: Support Contact Info (WhatsApp, Phone, Email) and Financial Constants 
  // (Fees, Tax) have been moved to Firestore 'app_config' collection for 
  // dynamic management without app updates. 
  // Use ConfigProvider to access these values.

  static const String appVersion = '2.4.0';
  static const String appBuildNumber = '240';
}
