import 'package:flutter/material.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/word_safe_text.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:go_router/go_router.dart';

/// "Personal details" item shown next to the trust score (T-0172).
///
/// Unfinished until the user has a date of birth and consent to the current
/// privacy text. It carries no points: the 100-point score is unchanged (see
/// the T-0172 notes for how it could weigh this item). Only the owner sees it.
/// Tapping it (or the link) opens the details screen; this is the only place a
/// skipped user is asked again.
class PersonalDetailsTrustItem extends StatefulWidget {
  const PersonalDetailsTrustItem({
    super.key,
    required this.accent,
    this.loader = UserPrivateDetailsService.getMine,
    this.onOpen,
  });

  final Color accent;
  final Future<UserPrivateDetails?> Function() loader;

  /// Opens the details screen; defaults to the pushed route. The item reloads
  /// when it returns.
  final Future<void> Function(BuildContext context)? onOpen;

  @override
  State<PersonalDetailsTrustItem> createState() =>
      _PersonalDetailsTrustItemState();
}

class _PersonalDetailsTrustItemState extends State<PersonalDetailsTrustItem> {
  bool? _done; // null = unknown (loading or failed): show nothing

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await widget.loader();
      final done = row != null &&
          row.dateOfBirth != null &&
          row.hasConsent &&
          row.consentVersion == AppInfo.privacyConsentVersion;
      if (mounted) setState(() => _done = done);
    } catch (_) {
      // Unknown: do not claim "missing" when the read failed.
    }
  }

  Future<void> _open() async {
    final open = widget.onOpen;
    if (open != null) {
      await open(context);
    } else {
      await context.push(AppRoutes.personalDetailsEdit);
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    if (done == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    const doneColor = Color(0xFF0B7A3B);
    final accentText = authAccentText(widget.accent);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          container: true,
          label:
              '${l10n.pdTrustTitle}. ${done ? l10n.pdTrustDone : l10n.pdTrustMissing}',
          excludeSemantics: true,
          onTap: _open,
          child: InkWell(
            key: const ValueKey('personal-details-trust-item'),
            onTap: _open,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: done ? const Color(0xFFE7FFED) : kDarkWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: done
                      ? doneColor.withValues(alpha: 0.25)
                      : kBorderColorTextField,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: done ? doneColor : kSubTitleColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WordSafeText(
                          l10n.pdTrustTitle,
                          maxLines: 3,
                          minScale: 0.85,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        WordSafeText(
                          done ? l10n.pdTrustDone : l10n.pdTrustMissing,
                          maxLines: 5,
                          minScale: 0.85,
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            fontSize: 12,
                          ),
                        ),
                        if (!done)
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                l10n.pdTrustAdd,
                                style: kTextStyle.copyWith(
                                  color: accentText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
