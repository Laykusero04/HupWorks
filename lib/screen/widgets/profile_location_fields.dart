import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:latlong2/latlong.dart';

import 'constant.dart';
import 'map_location_picker_screen.dart';

/// Country / city text fields plus a **Pick on map** action (center pin).
class ProfileLocationFields extends StatelessWidget {
  const ProfileLocationFields({
    super.key,
    required this.countryController,
    required this.cityController,
    this.accentColor,
    this.initialLatitude,
    this.initialLongitude,
    this.onCoordinatesChanged,
  });

  final TextEditingController countryController;
  final TextEditingController cityController;
  final Color? accentColor;
  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(double latitude, double longitude)? onCoordinatesChanged;

  Future<void> _openMap(BuildContext context) async {
    final LatLng? initialPosition = initialLatitude != null && initialLongitude != null
        ? LatLng(initialLatitude!, initialLongitude!)
        : null;
    final result = await Navigator.of(context).push<MapLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          purpose: MapLocationPickerPurpose.profile,
          initialCity: cityController.text,
          initialCountry: countryController.text,
          initialPosition: initialPosition,
          accentColor: accentColor,
        ),
      ),
    );
    if (result == null) return;
    if (result.country != null && result.country!.isNotEmpty) {
      countryController.text = result.country!;
    }
    if (result.city != null && result.city!.isNotEmpty) {
      cityController.text = result.city!;
    }
    onCoordinatesChanged?.call(result.latitude, result.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = accentColor ?? kPrimaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openMap(context),
          icon: Icon(FeatherIcons.mapPin, size: 18, color: accent),
          label: Text(
            context.l10n.pickLocationOnMap,
            style: kTextStyle.copyWith(color: accent, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.45)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.mapPinConfirmHint,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: countryController,
          keyboardType: TextInputType.name,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.next,
          decoration: kInputDecoration.copyWith(
            labelText: context.l10n.country,
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: context.l10n.mapOrType,
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: cityController,
          keyboardType: TextInputType.name,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.next,
          decoration: kInputDecoration.copyWith(
            labelText: context.l10n.city,
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: context.l10n.mapOrType,
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
