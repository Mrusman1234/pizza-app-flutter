import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Calculates distance between two points in kilometers.
  static double calculateDistance(double lat1, double lon1, double lat2, double lng2) {
    double distanceInMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lng2);
    return distanceInMeters / 1000; // Convert to km
  }

  /// Checks if a point is within a specific radius of another point.
  static bool isWithinRadius({
    required double userLat,
    required double userLng,
    required double restaurantLat,
    required double restaurantLng,
    required double radiusInKm,
  }) {
    double distance = calculateDistance(userLat, userLng, restaurantLat, restaurantLng);
    return distance <= radiusInKm;
  }
}
