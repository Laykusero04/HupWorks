import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Shared reverse-geocoding helpers for map pickers.
abstract final class MapGeocoding {
  static String cityFromPlacemark(Placemark p) {
    for (final s in [
      p.locality,
      p.subLocality,
      p.subAdministrativeArea,
      p.administrativeArea,
      p.name,
    ]) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return '';
  }

  /// Human-readable label for job posts (e.g. "Dhaka, Bangladesh").
  static String locationLabelFromPlacemark(Placemark p) {
    final city = cityFromPlacemark(p);
    final country = p.country?.trim() ?? '';
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (country.isNotEmpty && country != city) parts.add(country);
    if (parts.isNotEmpty) return parts.join(', ');
    final street = p.street?.trim();
    if (street != null && street.isNotEmpty) return street;
    return '';
  }

  static Future<LatLng?> latLngFromAddress(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      final locs = await locationFromAddress(q);
      if (locs.isEmpty) return null;
      return LatLng(locs.first.latitude, locs.first.longitude);
    } catch (_) {
      return null;
    }
  }
}
