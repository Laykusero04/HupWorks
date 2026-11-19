import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Max jobs shown in the client home "Your recent jobs" section (T-0166).
/// Kept at 3: with the extra date line each card is ~95dp tall, and the
/// "See all" link opens the My Jobs tab for the rest.
const int kHomeRecentJobsLimit = 3;

/// Newest first by `created_at` (rows with no/invalid date go last), capped
/// at [limit]. Does not mutate [jobs].
List<Map<String, dynamic>> newestJobsFirst(
  List<Map<String, dynamic>> jobs, {
  int limit = kHomeRecentJobsLimit,
}) {
  DateTime? created(Map<String, dynamic> j) =>
      DateTime.tryParse('${j['created_at'] ?? ''}');
  final sorted = List<Map<String, dynamic>>.of(jobs);
  sorted.sort((a, b) {
    final da = created(a);
    final db = created(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });
  return sorted.take(limit).toList();
}

/// "Posted 12 Nov 2026" / "Geplaatst op 12 nov. 2026". Empty when no date.
class RecentJobPostedDate extends StatelessWidget {
  const RecentJobPostedDate({super.key, required this.createdAt});

  final Object? createdAt;

  @override
  Widget build(BuildContext context) {
    final date = AppDateFormat.tryDMmmY(
        '${createdAt ?? ''}', AppDateFormat.localeOf(context));
    if (date == null) return const SizedBox.shrink();
    return Text(
      context.l10n.recentJobPostedOn(date),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 11),
    );
  }
}
