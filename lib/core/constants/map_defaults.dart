import 'package:latlong2/latlong.dart';

/// Default map camera when no prior pin or address is known.
abstract final class MapDefaults {
  static const LatLng fallbackCenter = LatLng(23.8103, 90.4125);
}
