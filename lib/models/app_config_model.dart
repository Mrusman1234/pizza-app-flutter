class AppConfigModel {
  final double baseDeliveryFee;
  final double taxRate; // e.g. 0.05 for 5%
  final String minVersion;
  final String latestVersion;
  final String supportPhone;
  final String supportEmail;

  AppConfigModel({
    required this.baseDeliveryFee,
    required this.taxRate,
    required this.minVersion,
    required this.latestVersion,
    required this.supportPhone,
    required this.supportEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'baseDeliveryFee': baseDeliveryFee,
      'taxRate': taxRate,
      'min_version': minVersion,
      'latest_version': latestVersion,
      'supportPhone': supportPhone,
      'supportEmail': supportEmail,
    };
  }

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      baseDeliveryFee: (map['baseDeliveryFee'] as num? ?? 50.0).toDouble(),
      taxRate: (map['taxRate'] as num? ?? 0.05).toDouble(),
      minVersion: map['min_version'] ?? '1.0.0',
      latestVersion: map['latest_version'] ?? '1.0.0',
      supportPhone: map['supportPhone'] ?? '',
      supportEmail: map['supportEmail'] ?? '',
    );
  }
}
