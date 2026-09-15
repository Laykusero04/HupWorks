import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/seller_standing.dart';
import 'package:freelancer/core/utils/talent_seller_filters.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:latlong2/latlong.dart';

import 'constant.dart';
import 'map_location_picker_screen.dart';

/// Opens the shared talent filter bottom sheet. Returns applied filters, or
/// `null` if dismissed without Apply.
///
/// [origin] is updated when the employer picks a map pin (saved to profile).
Future<TalentSellerFilters?> showTalentFilterSheet(
  BuildContext context, {
  required TalentSellerFilters initial,
  required TalentFilterOrigin origin,
  required ValueChanged<TalentFilterOrigin> onOriginChanged,
}) async {
  final l10n = context.l10n;
  var draftVerified = initial.verifiedOnly;
  var draftStanding = initial.standing;
  var draftMinRating = initial.minRating;
  var draftUseDistance = initial.maxDistanceKm != null;
  var draftDistanceKm = (initial.maxDistanceKm ??
          TalentSellerFilters.distanceDefaultKm)
      .clamp(
        TalentSellerFilters.distanceMinKm,
        TalentSellerFilters.distanceMaxKm,
      );
  var draftOrigin = origin;

  final applied = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget sectionLabel(String text) => Text(
                text,
                style: kTextStyle.copyWith(
                  color: kLightNeutralColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );

          Widget chip({
            required String label,
            required bool selected,
            required VoidCallback onTap,
          }) {
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onTap(),
              selectedColor: kPrimaryColor.withValues(alpha: 0.15),
              labelStyle: kTextStyle.copyWith(
                color: selected ? kPrimaryColor : kNeutralColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: kDarkWhite,
              side: BorderSide(
                color: selected ? kPrimaryColor : kBorderColorTextField,
              ),
            );
          }

          Future<void> pickLocation() async {
            final LatLng? initialPos =
                draftOrigin.hasCoordinates
                    ? LatLng(draftOrigin.latitude!, draftOrigin.longitude!)
                    : null;
            final result =
                await Navigator.of(ctx).push<MapLocationPickerResult>(
              MaterialPageRoute(
                builder: (_) => MapLocationPickerScreen(
                  purpose: MapLocationPickerPurpose.profile,
                  initialCity: draftOrigin.city,
                  initialCountry: draftOrigin.country,
                  initialPosition: initialPos,
                  accentColor: kPrimaryColor,
                ),
              ),
            );
            if (result == null) return;
            try {
              await ProfileService.updateProfile({
                if (result.country != null && result.country!.isNotEmpty)
                  'country': result.country,
                if (result.city != null && result.city!.isNotEmpty)
                  'city': result.city,
                'latitude': result.latitude,
                'longitude': result.longitude,
              });
              final next = TalentFilterOrigin(
                latitude: result.latitude,
                longitude: result.longitude,
                city: result.city,
                country: result.country,
              );
              setSheetState(() => draftOrigin = next);
              onOriginChanged(next);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.errorWithDetail('$e'))),
                );
              }
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                16 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kBorderColorTextField,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.filterTalent,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionLabel(l10n.statusVerified),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                chip(
                                  label: l10n.filterAll,
                                  selected: draftVerified != true,
                                  onTap: () => setSheetState(
                                    () => draftVerified = null,
                                  ),
                                ),
                                chip(
                                  label: l10n.statusVerified,
                                  selected: draftVerified == true,
                                  onTap: () => setSheetState(
                                    () => draftVerified = true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            sectionLabel(l10n.standingTitle),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                chip(
                                  label: l10n.filterAll,
                                  selected: draftStanding == null,
                                  onTap: () => setSheetState(
                                    () => draftStanding = null,
                                  ),
                                ),
                                for (final standing in SellerStanding.values)
                                  chip(
                                    label: standing.label(l10n),
                                    selected: draftStanding == standing,
                                    onTap: () => setSheetState(
                                      () => draftStanding = standing,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            sectionLabel(l10n.filterMinRating),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                chip(
                                  label: l10n.filterAll,
                                  selected: draftMinRating == null,
                                  onTap: () => setSheetState(
                                    () => draftMinRating = null,
                                  ),
                                ),
                                for (final rating
                                    in TalentSellerFilters.minRatingOptions)
                                  chip(
                                    label: l10n.ratingAtLeast(
                                      rating.toStringAsFixed(1),
                                    ),
                                    selected: draftMinRating == rating,
                                    onTap: () => setSheetState(
                                      () => draftMinRating = rating,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            sectionLabel(l10n.jobAlertLocationSection),
                            const SizedBox(height: 8),
                            Text(
                              draftOrigin.hasCoordinates
                                  ? (draftOrigin.locationLabel.isNotEmpty
                                      ? draftOrigin.locationLabel
                                      : l10n.jobAlertLocationSet)
                                  : l10n.jobAlertLocationMissing,
                              style: kTextStyle.copyWith(
                                color: kSubTitleColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: pickLocation,
                              icon: const Icon(Icons.map_outlined),
                              label: Text(l10n.pickLocationOnMap),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: draftUseDistance,
                              onChanged: (v) =>
                                  setSheetState(() => draftUseDistance = v),
                              title: Text(
                                l10n.filterLimitNearby,
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                ),
                              ),
                              activeThumbColor: kPrimaryColor,
                            ),
                            if (draftUseDistance)
                              Slider(
                                value: draftDistanceKm,
                                min: TalentSellerFilters.distanceMinKm,
                                max: TalentSellerFilters.distanceMaxKm,
                                divisions: 19,
                                label: l10n.jobAlertWithinKm(
                                  draftDistanceKm.round(),
                                ),
                                onChanged: (v) => setSheetState(
                                  () => draftDistanceKm = v,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                draftVerified = null;
                                draftStanding = null;
                                draftMinRating = null;
                                draftUseDistance = false;
                                draftDistanceKm =
                                    TalentSellerFilters.distanceDefaultKm;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kNeutralColor,
                              side: const BorderSide(
                                color: kBorderColorTextField,
                              ),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.filterClear),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (draftUseDistance &&
                                  !draftOrigin.hasCoordinates) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.jobAlertNeedProfileLocation,
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(ctx, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: kWhite,
                              minimumSize: const Size.fromHeight(46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.filterApply),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (applied != true) return null;
  return TalentSellerFilters(
    verifiedOnly: draftVerified,
    standing: draftStanding,
    minRating: draftMinRating,
    maxDistanceKm: draftUseDistance ? draftDistanceKm : null,
  );
}

/// Horizontal active-filter chips + clear-all.
class TalentFilterActiveChips extends StatelessWidget {
  const TalentFilterActiveChips({
    super.key,
    required this.filters,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final TalentSellerFilters filters;
  final ValueChanged<TalentSellerFilters> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!filters.hasActive) return const SizedBox.shrink();
    final l10n = context.l10n;

    Widget pill(String label, VoidCallback onClear) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InputChip(
          label: Text(label),
          onDeleted: onClear,
          deleteIconColor: kPrimaryColor,
          backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
          side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.35)),
          labelStyle: kTextStyle.copyWith(
            color: kPrimaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filters.verifiedOnly == true)
              pill(
                l10n.statusVerified,
                () => onChanged(filters.copyWith(clearVerified: true)),
              ),
            if (filters.standing != null)
              pill(
                filters.standing!.label(l10n),
                () => onChanged(filters.copyWith(clearStanding: true)),
              ),
            if (filters.minRating != null)
              pill(
                l10n.ratingAtLeast(filters.minRating!.toStringAsFixed(1)),
                () => onChanged(filters.copyWith(clearMinRating: true)),
              ),
            if (filters.maxDistanceKm != null)
              pill(
                l10n.jobAlertWithinKm(filters.maxDistanceKm!.round()),
                () => onChanged(filters.copyWith(clearMaxDistance: true)),
              ),
            TextButton(
              onPressed: () => onChanged(TalentSellerFilters.empty),
              style: TextButton.styleFrom(
                foregroundColor: kSubTitleColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.clearFilters,
                style: kTextStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tune button with optional badge count (matches talent browse).
class TalentFilterButton extends StatelessWidget {
  const TalentFilterButton({
    super.key,
    required this.filters,
    required this.onPressed,
    this.size = 48,
  });

  final TalentSellerFilters filters;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final active = filters.hasActive;
    return Material(
      color: active ? kPrimaryColor.withValues(alpha: 0.12) : kDarkWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? kPrimaryColor : kBorderColorTextField,
            ),
          ),
          child: Badge(
            isLabelVisible: active,
            label: Text('${filters.activeCount}'),
            backgroundColor: kPrimaryColor,
            child: Icon(
              Icons.tune_rounded,
              color: active ? kPrimaryColor : kNeutralColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
