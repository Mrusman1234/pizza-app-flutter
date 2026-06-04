import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Requests location permissions and returns true if granted.
  Future<bool> requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Specialized check for background permission (Riders only)
  Future<bool> requestBackgroundPermission() async {
    if (kIsWeb) return true;
    
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      // On some Android versions, you might need to guide the user to settings 
      // if they don't select "Allow all the time" immediately.
      return permission == LocationPermission.always;
    }

    return true;
  }

  /// Starts tracking the device's location.
  /// [onLocationChanged] is called whenever the position changes.
  Future<void> startTracking(Function(Position) onLocationChanged) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    final LocationSettings locationSettings = kIsWeb 
      ? const LocationSettings(accuracy: LocationAccuracy.high)
      : AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10),
          // ── FOREGROUND SERVICE ──────────────────────────────────────────
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Order Delivery in progress",
            notificationTitle: "Rider Tracking Active",
            enableWakeLock: true,
          ),
        );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        onLocationChanged(position);
      },
      onError: (e) {
        debugPrint('Location tracking error: $e');
      },
    );
  }

  /// Stops tracking the device's location.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Gets the current position once.
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
}
