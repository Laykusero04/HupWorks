import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'constant.dart';

/// Read-only map preview for a job pin (non-interactive except scroll parent).
class JobLocationMapPreview extends StatelessWidget {
  const JobLocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.locationLabel,
    this.height = 180,
    this.accentColor,
  });

  final double latitude;
  final double longitude;
  final String? locationLabel;
  final double height;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    final accent = accentColor ?? kPrimaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = locationLabel?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                    backgroundColor: kDarkWhite,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.prolancer.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on, color: accent, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                      child: Text(
                        '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                        style: kTextStyle.copyWith(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Parses job_post map fields; returns null if no coordinates.
({double lat, double lng})? jobPostCoordinates(Map<String, dynamic>? job) {
  if (job == null) return null;
  final lat = job['latitude'];
  final lng = job['longitude'];
  if (lat is! num || lng is! num) return null;
  return (lat: lat.toDouble(), lng: lng.toDouble());
}

/// Widget that shows map preview when coords exist, else text-only location row.
class JobLocationSection extends StatelessWidget {
  const JobLocationSection({
    super.key,
    required this.job,
    this.accentColor,
  });

  final Map<String, dynamic>? job;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final location = (job?['location'] as String?)?.trim();
    final coords = jobPostCoordinates(job);

    if (coords == null && (location == null || location.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (coords != null) {
      return JobLocationMapPreview(
        latitude: coords.lat,
        longitude: coords.lng,
        locationLabel: location,
        accentColor: accentColor,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: accentColor ?? kPrimaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(location!, style: kTextStyle.copyWith(color: kSubTitleColor)),
        ),
      ],
    );
  }
}
