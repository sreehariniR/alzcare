// In a new file: lib/providers/mock_location_provider.dart

import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Using this for the LatLng type

class MockLocationProvider {
  // A base location, e.g., a park in a city
  static const LatLng _safeZoneCenter = LatLng(12.9716, 77.5946);
  bool _isOutsideSafeZone = false;

  // Toggles the simulation state
  void simulateLeavingSafeZone(bool isOutside) {
    _isOutsideSafeZone = isOutside;
  }

  // This function pretends to get the location from the watch
  LatLng getCurrentLocation() {
    if (_isOutsideSafeZone) {
      // Return a location far away to test alerts
      return const LatLng(13.0827, 80.2707); // A different city
    } else {
      // Return a location "wandering" near the center
      final random = Random();
      final latOffset = (random.nextDouble() - 0.5) * 0.001; // Small random walk
      final lonOffset = (random.nextDouble() - 0.5) * 0.001; // Small random walk
      return LatLng(
        _safeZoneCenter.latitude + latOffset,
        _safeZoneCenter.longitude + lonOffset,
      );
    }
  }
}