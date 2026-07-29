import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:latlong2/latlong.dart';

import 'constant.dart';
import 'map_location_picker_screen.dart';

enum JobLocationType { onsite, remote }

extension JobLocationTypeLabel on JobLocationType {
  String get label => switch (this) {
        JobLocationType.onsite => 'On-site',
        JobLocationType.remote => 'Remote',
      };

  IconData get icon => switch (this) {
        JobLocationType.onsite => Icons.location_on_outlined,
        JobLocationType.remote => Icons.laptop_outlined,
      };
}

/// Job post location section:
/// - Required radio: On-site / Remote
/// - On-site shows "Pin on map" + location text field
/// - Remote shows the text field only (no pin)
class JobLocationFields extends StatefulWidget {
  const JobLocationFields({
    super.key,
    required this.locationController,
    required this.pin,
    required this.onPinChanged,
    required this.locationType,
    required this.onLocationTypeChanged,
    this.accentColor,
  });

  final TextEditingController locationController;
  final LatLng? pin;
  final ValueChanged<LatLng?> onPinChanged;
  final JobLocationType locationType;
  final ValueChanged<JobLocationType> onLocationTypeChanged;
  final Color? accentColor;

  @override
  State<JobLocationFields> createState() => _JobLocationFieldsState();
}

class _JobLocationFieldsState extends State<JobLocationFields> {
  Future<void> _openMap() async {
    final result = await Navigator.of(context).push<MapLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          purpose: MapLocationPickerPurpose.job,
          initialLocation: widget.locationController.text,
          initialPosition: widget.pin,
          accentColor: widget.accentColor,
          title: 'Job location',
        ),
      ),
    );
    if (result == null) return;
    widget.onPinChanged(LatLng(result.latitude, result.longitude));
    final label = result.locationLabel?.trim();
    if (label != null && label.isNotEmpty) {
      widget.locationController.text = label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = widget.accentColor ?? kPrimaryColor;
    final isOnsite = widget.locationType == JobLocationType.onsite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              'Location',
              style: kTextStyle.copyWith(
                  color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(l10n.requiredFieldMark,
                style: kTextStyle.copyWith(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),

        // ── Radio tiles ─────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorderColorTextField, width: 1.5),
          ),
          child: Column(
            children: JobLocationType.values.map((type) {
              final selected = widget.locationType == type;
              final isLast = type == JobLocationType.values.last;
              return InkWell(
                onTap: () => widget.onLocationTypeChanged(type),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.07)
                        : Colors.transparent,
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: kBorderColorTextField)),
                  ),
                  child: Row(
                    children: [
                      Icon(type.icon,
                          size: 20,
                          color: selected ? accent : kLightNeutralColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          type.label,
                          style: kTextStyle.copyWith(
                            color:
                                selected ? accent : kNeutralColor,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected ? accent : kLightNeutralColor,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── On-site: map pin button ──────────────────────────────────────
        if (isOnsite) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _openMap,
            icon: Icon(FeatherIcons.mapPin, size: 18, color: accent),
            label: Text(
              widget.pin != null ? 'Change map pin' : 'Pin on map',
              style: kTextStyle.copyWith(
                  color: accent, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (widget.pin != null) ...[
            const SizedBox(height: 4),
            Text(
              '📍 ${widget.pin!.latitude.toStringAsFixed(4)}, ${widget.pin!.longitude.toStringAsFixed(4)}',
              style: kTextStyle.copyWith(
                  color: kLightNeutralColor, fontSize: 12),
            ),
          ],
        ],

        // ── Location text field (all types) ─────────────────────────────
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.locationController,
          keyboardType: TextInputType.text,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.next,
          decoration: kInputDecoration.copyWith(
            labelText: isOnsite ? 'Address / Area' : 'Location',
            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
            hintText: switch (widget.locationType) {
              JobLocationType.onsite => 'City or area (map or type)',
              JobLocationType.remote => 'e.g. Remote, any region',
            },
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: kLightNeutralColor),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
