import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeoFix {
  const GeoFix({required this.city, this.lat, this.lng});

  final String city;
  final double? lat;
  final double? lng;
}

class LocationService {
  Future<GeoFix?> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final mark = marks.isEmpty ? null : marks.first;
      final city = [
        mark?.locality,
        mark?.subAdministrativeArea,
        mark?.administrativeArea,
      ].whereType<String>().firstWhere(
            (e) => e.trim().isNotEmpty,
            orElse: () => '',
          );
      if (city.isEmpty) {
        return GeoFix(city: '', lat: pos.latitude, lng: pos.longitude);
      }
      return GeoFix(city: city, lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
