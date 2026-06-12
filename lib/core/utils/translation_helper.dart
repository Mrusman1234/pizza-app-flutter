class TranslationHelper {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'confirm_order': 'Confirm Order',
      'delivered': 'Delivered',
      'total': 'Total',
      'place_order': 'Place Order',
    },
    'ur': {
      'confirm_order': 'آرڈر کی تصدیق کریں',
      'delivered': 'ڈیلیور کر دیا گیا',
      'total': 'کل رقم',
      'place_order': 'آرڈر دیں',
    },
  };

  static String getString(String key, String locale) {
    return _localizedValues[locale]?[key] ?? key;
  }
}
