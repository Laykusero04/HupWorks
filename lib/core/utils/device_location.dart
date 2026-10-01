import 'package:geolocator/geolocator.dart';

/// Result of requesting the device's current GPS fix.
class DeviceLocationFix {
  const DeviceLocationFix._({
    this.latitude,
    this.longitude,
    this.errorCode,
  });

  const DeviceLocationFix.ok(double latitude, double longitude)
      : this._(latitude: latitude, longitude: longitude);

  const DeviceLocationFix.failed(String errorCode)
      : this._(errorCode: errorCode);

  final double? latitude;
  final double? longitude;

  /// `services_off` | `denied` | `denied_forever` | `unavailable`
  final String? errorCode;

  bool get isOk => latitude != null && longitude != null;
}

/// Shared GPS helper for attendance and map flows.
class DeviceLocation {
  DeviceLocation._();

  static Future<DeviceLocationFix> getCurrentFix({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        return const DeviceLocationFix.failed('services_off');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const DeviceLocationFix.failed('denied');
      }
      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocationFix.failed('denied_forever');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return DeviceLocationFix.ok(pos.latitude, pos.longitude);
    } catch (_) {
      return const DeviceLocationFix.failed('unavailable');
    }
  }
}
