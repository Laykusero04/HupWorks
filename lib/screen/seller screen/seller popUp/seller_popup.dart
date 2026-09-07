import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/auth_navigation.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/block_service.dart';
import 'package:freelancer/services/report_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/icons.dart';

// ---------------------------------------------------------------------------
// SaveProfilePopUp — shown after profile creation
// ---------------------------------------------------------------------------
class SaveProfilePopUp extends StatefulWidget {
  const SaveProfilePopUp({Key? key}) : super(key: key);

  @override
  State<SaveProfilePopUp> createState() => _SaveProfilePopUpState();
}

class _SaveProfilePopUpState extends State<SaveProfilePopUp> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 186,
              width: 209,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(image: AssetImage('images/success.png'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 15.0),
            Text(
              l10n.congratulations,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(height: 10.0),
            Text(
              l10n.profileSetupCompleteBody,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            Button(
              containerBg: kPrimaryColor,
              borderColor: Colors.transparent,
              buttonText: l10n.done,
              textColor: kWhite,
              onPressed: () {
                // Do not finish()/pop first — that disposes this context and
                // AuthNavigation would no-op. It pops overlays itself, then goes home.
                AuthNavigation.goToHomeAfterAuth(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BlockingReasonPopUp — soft-block confirm (chat / profile)
// ---------------------------------------------------------------------------
class BlockingReasonPopUp extends StatefulWidget {
  const BlockingReasonPopUp({
    Key? key,
    required this.blockedUserId,
    this.blockedUserName,
    this.orderId,
    this.onBlocked,
  }) : super(key: key);

  final String blockedUserId;
  final String? blockedUserName;
  final String? orderId;
  final VoidCallback? onBlocked;

  @override
  State<BlockingReasonPopUp> createState() => _BlockingReasonPopUpState();
}

class _BlockingReasonPopUpState extends State<BlockingReasonPopUp> {
  bool _loading = true;
  bool _submitting = false;
  bool _hasOpenObligation = false;
  bool _alsoReportPayment = false;
  List<String> _openOrderIds = const [];

  @override
  void initState() {
    super.initState();
    _loadObligation();
  }

  Future<void> _loadObligation() async {
    try {
      final ids = await BlockService.openOrderIdsWith(widget.blockedUserId);
      if (!mounted) return;
      setState(() {
        _openOrderIds = ids;
        _hasOpenObligation = ids.isNotEmpty;
        _alsoReportPayment = ids.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmBlock() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      final result = await BlockService.blockUser(
        blockedUserId: widget.blockedUserId,
      );

      if (_alsoReportPayment) {
        final orderId = widget.orderId?.trim().isNotEmpty == true
            ? widget.orderId!.trim()
            : (result.openOrderIds.isNotEmpty
                ? result.openOrderIds.first
                : (_openOrderIds.isNotEmpty ? _openOrderIds.first : null));
        final name = widget.blockedUserName?.trim();
        try {
          await ReportService.createReport(
            reportedUserId: widget.blockedUserId,
            reason: 'Payment or contract dispute',
            details: name == null || name.isEmpty
                ? 'Blocked user while an open or unpaid job may still exist. Please review payment status.'
                : 'Blocked $name while an open or unpaid job may still exist. Please review payment status.',
            orderId: orderId,
          );
        } catch (_) {
          // Block already succeeded; report is best-effort for PoC.
        }
      }

      if (!mounted) return;
      final open = result.hasOpenObligation || _hasOpenObligation;
      final messenger = ScaffoldMessenger.maybeOf(context);
      widget.onBlocked?.call();
      finish(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            open ? l10n.blockSuccessOpenObligation : l10n.blockSuccess,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = widget.blockedUserName?.trim();
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.blockUserTitle,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _submitting ? null : () => finish(context),
                  child: const Icon(FeatherIcons.x, color: kSubTitleColor),
                ),
              ],
            ),
            if (name != null && name.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Text(
                name,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16.0),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Text(
                _hasOpenObligation
                    ? l10n.blockUserBodyOpenObligation
                    : l10n.blockUserBody,
                style: kTextStyle.copyWith(color: kSubTitleColor),
              ),
            if (!_loading && _hasOpenObligation) ...[
              const SizedBox(height: 12.0),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _alsoReportPayment,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _alsoReportPayment = v ?? false),
                title: Text(
                  l10n.blockAlsoReportPayment,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Button(
                    containerBg: kWhite,
                    borderColor: Colors.red,
                    buttonText: l10n.cancel,
                    textColor: Colors.red,
                    onPressed: _submitting ? () {} : () => finish(context),
                  ),
                ),
                Expanded(
                  child: Button(
                    containerBg: kPrimaryColor,
                    borderColor: Colors.transparent,
                    buttonText: _submitting ? '…' : l10n.block,
                    textColor: kWhite,
                    onPressed: _submitting || _loading ? () {} : _confirmBlock,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ReviewSubmittedPopUp — shown after leaving a review
// ---------------------------------------------------------------------------
class ReviewSubmittedPopUp extends StatefulWidget {
  const ReviewSubmittedPopUp({Key? key}) : super(key: key);

  @override
  State<ReviewSubmittedPopUp> createState() => _ReviewSubmittedPopUpState();
}

class _ReviewSubmittedPopUpState extends State<ReviewSubmittedPopUp> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10.0),
            Container(
              height: 124,
              width: 124,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: kPrimaryColor,
                size: 50,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              l10n.reviewSuccessTitle,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(height: 10.0),
            Text(
              l10n.reviewSuccessBody,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
            const SizedBox(height: 20.0),
            ButtonGlobalWithoutIcon(
                buttontext: l10n.gotIt,
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonTextColor: kWhite),
          ],
        ),
      ),
    );
  }
}
