import 'package:flutter_map/flutter_map.dart';

/// Shared OSM tiles (no third-party API key).
abstract final class AppMapTiles {
  static const userAgentPackageName = 'com.prolancer.app';

  /// OpenStreetMap raster tiles — works without a CARTO/Mapbox key.
  static TileLayer osm({required bool isDark}) {
    // OSM does not ship a separate dark style; same tiles for both themes.
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: userAgentPackageName,
      maxNativeZoom: 19,
    );
  }

  static List<SourceAttribution> attributions() => [
        TextSourceAttribution('© OpenStreetMap contributors'),
      ];
}
