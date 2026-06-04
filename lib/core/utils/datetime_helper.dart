import 'package:intl/intl.dart';

class DateTimeHelper {
  /// Checks if the current time is within the restaurant's operating hours.
  /// hours: { 'monday': { 'open': '09:00', 'close': '22:00' }, ... }
  static bool isOpenNow(Map<String, dynamic>? hours) {
    if (hours == null || hours.isEmpty) return true; // Default to open if no hours set

    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now).toLowerCase();
    
    if (!hours.containsKey(dayName)) return false; // Closed today

    final dayHours = hours[dayName];
    final String? openStr = dayHours['open'];
    final String? closeStr = dayHours['close'];

    if (openStr == null || closeStr == null) return false;

    final nowTime = DateFormat('HH:mm').format(now);
    
    // Simple string comparison for HH:mm format works
    return nowTime.compareTo(openStr) >= 0 && nowTime.compareTo(closeStr) <= 0;
  }
}
