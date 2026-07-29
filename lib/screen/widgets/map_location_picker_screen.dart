import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/map_defaults.dart';
import 'constant.dart';
import 'map_geocoding.dart';

enum MapLocationPickerPurpose { profile, job }

/// Result of [MapLocationPickerScreen].
class MapLocationPickerResult {
  const MapLocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.locationLabel,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  /// Filled for [MapLocationPickerPurpose.job] (display + `job_posts.location`).
  final String? locationLabel;
}

/// Full-screen map with a **fixed center pin** (MeetRadius-style [flutter_map]).
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    super.key,
    this.purpose = MapLocationPickerPurpose.profile,
    this.initialCity,
    this.initialCountry,
    this.initialLocation,
    this.initialPosition,
    this.accentColor,
    this.title,
  });

  final MapLocationPickerPurpose purpose;
  final String? initialCity;
  final String? initialCountry;
  /// Job: existing location text to geocode for initial camera.
  final String? initialLocation;
  final LatLng? initialPosition;
  final Color? accentColor;
  final String? title;

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _center;
  bool _resolving = false;
  String? _previewLine;

  Color get _accent => widget.accentColor ?? kPrimaryColor;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? MapDefaults.fallbackCenter;
    WidgetsBinding.instance.addPostFrameCallback((_) => _moveToInitial());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _moveToInitial() async {
    LatLng? target = widget.initialPosition;
    if (target == null) {
      if (widget.purpose == MapLocationPickerPurpose.profile) {
        final city = widget.initialCity?.trim() ?? '';
        final country = widget.initialCountry?.trim() ?? '';
        if (city.isNotEmpty || country.isNotEmpty) {
          final parts = <String>[];
          if (city.isNotEmpty) parts.add(city);
          if (country.isNotEmpty) parts.add(country);
          target = await MapGeocoding.latLngFromAddress(parts.join(', '));
        }
      } else {
        final loc = widget.initialLocation?.trim() ?? '';
        if (loc.isNotEmpty) {
          target = await MapGeocoding.latLngFromAddress(loc);
        }
      }
    }
    if (!mounted || target == null) return;
    final resolved = target;
    setState(() => _center = resolved);
    _mapController.move(resolved, 14);
  }

  void _syncCenterFromCamera() {
    final c = _mapController.camera.center;
    if (_center.latitude != c.latitude || _center.longitude != c.longitude) {
      setState(() => _center = c);
    }
  }

  Future<void> _confirm() async {
    _syncCenterFromCamera();
    if (!mounted) return;
    setState(() {
      _resolving = true;
      _previewLine = null;
    });
    try {
      final marks = await placemarkFromCoordinates(_center.latitude, _center.longitude);
      if (!mounted) return;
      if (marks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mapNoAddressForPoint)),
        );
        return;
      }
      final p = marks.first;
      final city = MapGeocoding.cityFromPlacemark(p);
      final country = p.country?.trim() ?? '';
      final label = MapGeocoding.locationLabelFromPlacemark(p);

      if (widget.purpose == MapLocationPickerPurpose.profile) {
        if (city.isEmpty && country.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.mapNoCityCountryFound)),
          );
          return;
        }
        setState(() => _previewLine = [city, country].where((e) => e.isNotEmpty).join(', '));
      } else {
        final display = label.isNotEmpty
            ? label
            : '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
        setState(() => _previewLine = display);
      }

      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;

      if (widget.purpose == MapLocationPickerPurpose.profile) {
        Navigator.of(context).pop(
          MapLocationPickerResult(
            latitude: _center.latitude,
            longitude: _center.longitude,
            city: city,
            country: country,
          ),
        );
      } else {
        Navigator.of(context).pop(
          MapLocationPickerResult(
            latitude: _center.latitude,
            longitude: _center.longitude,
            locationLabel: label.isNotEmpty
                ? label
                : '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mapAddressLookupFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = widget.initialPosition ?? _center;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? context.l10n.mapPickLocation, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              widget.purpose == MapLocationPickerPurpose.job
                  ? context.l10n.mapMovePinJob
                  : context.l10n.mapMovePinProfile,
              style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13, height: 1.35),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: start,
                      initialZoom: 14,
                      minZoom: 4,
                      maxZoom: 18,
                      backgroundColor: kDarkWhite,
                      onMapEvent: (event) {
                        if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
                          _syncCenterFromCamera();
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.prolancer.app',
                      ),
                      RichAttributionWidget(
                        alignment: AttributionAlignment.bottomRight,
                        attributions: [
                          TextSourceAttribution('OpenStreetMap contributors, CARTO'),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -22),
                        child: Icon(
                          Icons.place,
                          size: 52,
                          color: _accent,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Color(0x66000000), offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
              style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
            ),
          ),
          if (_previewLine != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_previewLine!, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12)),
            ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _resolving ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _resolving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.l10n.mapUseThisLocation),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
