import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../core/city.dart';

class GeoFix {
  const GeoFix({required this.city, this.lat, this.lng, this.district = ''});

  final String city;
  final double? lat;
  final double? lng;
  final String district;
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
      final district = [
        mark?.subLocality,
        mark?.thoroughfare,
        mark?.subThoroughfare,
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
      if (city.isEmpty) {
        return GeoFix(
          city: '',
          lat: pos.latitude,
          lng: pos.longitude,
          district: district,
        );
      }
      return GeoFix(
        city: cityLabel(city),
        lat: pos.latitude,
        lng: pos.longitude,
        district: district,
      );
    } catch (_) {
      return null;
    }
  }
}
