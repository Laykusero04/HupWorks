import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import 'constant.dart';
import 'map_location_picker_screen.dart';

/// Country / city text fields plus a **Pick on map** action (center pin).
class ProfileLocationFields extends StatelessWidget {
  const ProfileLocationFields({
    super.key,
    required this.countryController,
    required this.cityController,
    this.accentColor,
  });

  final TextEditingController countryController;
  final TextEditingController cityController;
  final Color? accentColor;

  Future<void> _openMap(BuildContext context) async {
    final result = await Navigator.of(context).push<MapLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          purpose: MapLocationPickerPurpose.profile,
          initialCity: cityController.text,
          initialCountry: countryController.text,
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
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? kPrimaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openMap(context),
          icon: Icon(FeatherIcons.mapPin, size: 18, color: accent),
          label: Text(
            'Pick location on map',
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
          'Center the pin on your spot, then confirm.',
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: countryController,
          keyboardType: TextInputType.name,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.next,
          decoration: kInputDecoration.copyWith(
            labelText: 'Country',
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: 'Map or type',
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
            labelText: 'City',
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: 'Map or type',
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
