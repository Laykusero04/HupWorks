import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/job_location_map_preview.dart';
import 'package:freelancer/screen/widgets/map_location_picker_screen.dart';
import 'package:freelancer/services/job_posts_service.dart';

/// Ensures [jobPostId] has lat/lng before QR attendance can be shown.
///
/// Older jobs may only have address text. Prompts with a dialog, then opens the
/// map picker and persists the pin. Returns the job map (with coordinates) on
/// success, or `null` if the user cancels or save fails.
Future<Map<String, dynamic>?> ensureJobSitePinForQr({
  required BuildContext context,
  required String jobPostId,
  Map<String, dynamic>? jobPost,
  void Function(Map<String, dynamic> updated)? onUpdated,
}) async {
  Map<String, dynamic>? job = jobPost;
  if (jobPostCoordinates(job) == null) {
    try {
      job = await JobPostsService.getJobPostDetails(jobPostId);
    } catch (_) {
      // Fall through to dialog using whatever we have.
    }
  }

  if (jobPostCoordinates(job) != null) {
    onUpdated?.call(job!);
    return job;
  }

  if (!context.mounted) return null;
  final l10n = context.l10n;
  final goSet = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.jobSitePinRequiredTitle),
      content: Text(l10n.jobSitePinRequiredBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.setMapPin,
            style: kTextStyle.copyWith(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  if (goSet != true || !context.mounted) return null;

  final initialLocation = (job?['location'] as String?)?.trim();
  final result = await Navigator.of(context).push<MapLocationPickerResult>(
    MaterialPageRoute(
      builder: (_) => MapLocationPickerScreen(
        purpose: MapLocationPickerPurpose.job,
        initialLocation: initialLocation,
        title: l10n.jobSitePinPickerTitle,
      ),
    ),
  );
  if (result == null || !context.mounted) return null;

  try {
    final updated = await JobPostsService.updateJobLocation(
      jobPostId: jobPostId,
      latitude: result.latitude,
      longitude: result.longitude,
      location: result.locationLabel,
    );
    onUpdated?.call(updated);
    return updated;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
    return null;
  }
}
