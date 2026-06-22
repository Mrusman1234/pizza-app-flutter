class AppConfigModel {
  final String appName;
  final double baseDeliveryFee;
  final double taxRate; // e.g. 0.05 for 5%
  final double defaultCommission;
  final double minOrderAmount;
  final String minVersion;
  final String latestVersion;
  final String supportPhone;
  final String supportEmail;
  final String supportWhatsApp;
  final bool maintenanceMode;
  final bool ordersEnabled;
  final bool notificationsEnabled;

  AppConfigModel({
    required this.appName,
    required this.baseDeliveryFee,
    required this.taxRate,
    required this.defaultCommission,
    required this.minOrderAmount,
    required this.minVersion,
    required this.latestVersion,
    required this.supportPhone,
    required this.supportEmail,
    required this.supportWhatsApp,
    required this.maintenanceMode,
    required this.ordersEnabled,
    required this.notificationsEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'baseDeliveryFee': baseDeliveryFee,
      'taxRate': taxRate,
      'defaultCommission': defaultCommission,
      'minOrderAmount': minOrderAmount,
      'min_version': minVersion,
      'latest_version': latestVersion,
      'supportPhone': supportPhone,
      'supportEmail': supportEmail,
      'supportWhatsApp': supportWhatsApp,
      'maintenanceMode': maintenanceMode,
      'ordersEnabled': ordersEnabled,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      appName: map['appName'] ?? 'Pizza Hub Vehari',
      baseDeliveryFee: (map['baseDeliveryFee'] as num? ?? 50.0).toDouble(),
      taxRate: (map['taxRate'] as num? ?? 0.05).toDouble(),
      defaultCommission: (map['defaultCommission'] as num? ?? 10.0).toDouble(),
      minOrderAmount: (map['minOrderAmount'] as num? ?? 200.0).toDouble(),
      minVersion: map['min_version'] ?? '1.0.0',
      latestVersion: map['latest_version'] ?? '1.0.0',
      supportPhone: map['supportPhone'] ?? '+92 300 0000000',
      supportEmail: map['supportEmail'] ?? 'support@pizzahubvehari.com',
      supportWhatsApp: map['supportWhatsApp'] ?? '+92 300 0000000',
      maintenanceMode: map['maintenanceMode'] ?? false,
      ordersEnabled: map['ordersEnabled'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}
