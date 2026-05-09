import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<bool> handlePermission() async {
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

  /// Returns the student's exact current position (lat/lng).
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best));
  }

  /// Reverse-geocodes lat/lng into a human-readable place name.
  /// Returns something like "Kenyatta University, Kahawa West, Nairobi, Kenya"
  Future<String> getPlaceName(double latitude, double longitude) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Build a readable address from the available fields
        final parts = <String>[
          if (p.name != null && p.name!.isNotEmpty) p.name!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        // Remove consecutive duplicates (e.g. name == locality)
        final deduped = <String>[];
        for (final part in parts) {
          if (deduped.isEmpty || deduped.last != part) {
            deduped.add(part);
          }
        }
        if (deduped.isNotEmpty) return deduped.join(', ');
      }
    } catch (_) {
      // Geocoding can fail (no network, etc.) — fall back gracefully
    }
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Returns a short coordinate-direction string.
  String formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}° $latDir, ${lng.abs().toStringAsFixed(6)}° $lngDir';
  }
}
