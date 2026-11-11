import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/attendance_location.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/data/models/attendance_punch_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class AttendanceConfirmScreen extends StatefulWidget {
  final String token;
  final AttendanceResolveResult resolve;

  const AttendanceConfirmScreen({
    super.key,
    required this.token,
    required this.resolve,
  });

  @override
  State<AttendanceConfirmScreen> createState() =>
      _AttendanceConfirmScreenState();
}

class _AttendanceConfirmScreenState extends State<AttendanceConfirmScreen>
    with GuideHost<AttendanceConfirmScreen> {
  late String _selectedPunchType;
  bool _isSubmitting = false;

  final GlobalKey _guideSummaryKey = GlobalKey();
  final GlobalKey _guideTypeKey = GlobalKey(); // chips OR the QR-once hint
  final GlobalKey _guideLocationKey = GlobalKey();
  final GlobalKey _guideConfirmKey = GlobalKey();

  /// True once the push animation is over (targets at their final place).
  bool _routeSettled = false;

  @override
  String get guideScreenId => 'seller_attendance_confirm';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// Static data (from `widget.resolve`). Not ready while submitting: the
  /// button is replaced by a spinner and the GPS permission dialog may show.
  @override
  bool get guideDataReady => _routeSettled && !_isSubmitting;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  /// In QR-once mode with today's check-in done the button is a no-op
  /// (`onPressed: () {}`): it is not highlighted and has no step.
  bool get _confirmIsNoop => _isQrOnceMode && widget.resolve.checkedInToday;

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideSummaryKey,
          title: l10n.guideAttConfirmJobTitle,
          description: l10n.guideAttConfirmJobDesc),
      if (_isQrOnceMode)
        GuideStep(
            key: _guideTypeKey,
            title: l10n.guideAttConfirmOnceTitle,
            description: l10n.guideAttConfirmOnceDesc)
      else
        GuideStep(
            key: _guideTypeKey,
            title: l10n.guideAttConfirmTypeTitle,
            description: l10n.guideAttConfirmTypeDesc),
      GuideStep(
          key: _guideLocationKey,
          title: l10n.guideAttConfirmLocationTitle,
          description: l10n.guideAttConfirmLocationDesc,
          enableAutoScroll: true),
      if (!_confirmIsNoop)
        GuideStep(
            key: _guideConfirmKey,
            title: l10n.guideAttConfirmButtonTitle,
            description: l10n.guideAttConfirmButtonDesc,
            targetNearBottom: true,
            enableAutoScroll: true),
    ];
  }

  GuideAnchor _anchor(GlobalKey key, String title, String desc,
          {BorderRadius? radius}) =>
      GuideAnchor(
        key: key,
        scope: guideScope,
        title: title,
        description: desc,
        borderRadius: radius,
      );

  void _awaitRouteSettled() {
    if (!mounted) return;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted) {
      _settleRoute();
      return;
    }
    void listener(AnimationStatus st) {
      if (st == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        _settleRoute();
      }
    }

    anim.addStatusListener(listener);
  }

  void _settleRoute() {
    if (!mounted) return;
    setState(() => _routeSettled = true);
    scheduleGuide();
  }

  @override
  void initState() {
    super.initState();
    _selectedPunchType = widget.resolve.suggestedAction;
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final site = widget.resolve;
    if (site.latitude == null || site.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.attendanceNoSitePin)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final position = await readAttendancePosition();
      final result = await AttendanceService.recordAttendancePunch(
        token: widget.token,
        punchType: _selectedPunchType,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.hourReportId != null && result.punchType == 'out'
                ? '${l10n.attendancePunchRecorded(AttendanceFormat.punchLabel(result.punchType, l10n), AttendanceFormat.minutesLabel(result.minutesWorkedToday, l10n))} ${l10n.hoursSentForEmployerReview}'
                : l10n.attendancePunchRecorded(
                    AttendanceFormat.punchLabel(result.punchType, l10n),
                    AttendanceFormat.minutesLabel(
                        result.minutesWorkedToday, l10n),
                  ),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on AttendanceGpsException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final openSettings = switch (e.block) {
        AttendanceGpsBlock.servicesOff => Geolocator.openLocationSettings,
        AttendanceGpsBlock.deniedForever => Geolocator.openAppSettings,
        _ => null,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attendanceGpsMessage(l10n, e.block)),
          action: openSettings == null
              ? null
              : SnackBarAction(
                  label: l10n.settings,
                  onPressed: () {
                    openSettings();
                  },
                ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(attendanceRpcMessage(l10n, e))),
        );
      }
    }
  }

  String _statusText(AppLocalizations l10n, String locale) {
    final r = widget.resolve;
    if (AttendanceMode.normalize(r.attendanceMode) == AttendanceMode.qrOnce) {
      if (r.checkedInToday) return l10n.alreadyCheckedInToday;
      return l10n.readyForDailyCheckIn;
    }
    if (r.isClockedIn && r.lastPunchedAt != null) {
      return l10n.clockedInAt(
        AttendanceFormat.timeOfDay(r.lastPunchedAt!, locale),
      );
    }
    return l10n.notClockedInToday;
  }

  bool get _isQrOnceMode =>
      AttendanceMode.normalize(widget.resolve.attendanceMode) ==
      AttendanceMode.qrOnce;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final r = widget.resolve;
    final primaryIsIn = _selectedPunchType == 'in';

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.confirmAttendance,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [GuideInfoButton(host: this)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GuideAnchor.wrap(
              _anchor(_guideSummaryKey, l10n.guideAttConfirmJobTitle,
                  l10n.guideAttConfirmJobDesc,
                  radius: BorderRadius.circular(12)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderColorTextField),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.clientName,
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    if (r.location != null && r.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 18, color: kPrimaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.location!,
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: r.isClockedIn
                            ? const Color(0xFFE8F5E9)
                            : kDarkWhite,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusText(l10n, locale),
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: r.isClockedIn
                              ? const Color(0xFF2E7D32)
                              : kNeutralColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (r.todayPunches.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.calendarToday,
                style: kTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kNeutralColor,
                ),
              ),
              const SizedBox(height: 8),
              ...r.todayPunches.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          p.isClockIn ? Icons.login : Icons.logout,
                          size: 16,
                          color: p.isClockIn
                              ? const Color(0xFF2E7D32)
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AttendanceFormat.punchLabel(p.punchType, l10n)} • ${AttendanceFormat.timeOfDay(p.punchedAt, locale)}',
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.recordLabel,
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeutralColor,
              ),
            ),
            const SizedBox(height: 12),
            if (_isQrOnceMode) ...[
              // One Text is built at a time, so one key serves both.
              GuideAnchor.wrap(
                _anchor(_guideTypeKey, l10n.guideAttConfirmOnceTitle,
                    l10n.guideAttConfirmOnceDesc),
                r.checkedInToday
                    ? Text(
                        l10n.alreadyCheckedInTodayMessage,
                        style: kTextStyle.copyWith(
                            color: kSubTitleColor, height: 1.35),
                      )
                    : Text(
                        l10n.attendanceQrOnceDailyHint,
                        style: kTextStyle.copyWith(
                            color: kSubTitleColor, height: 1.35),
                      ),
              ),
            ] else ...[
              GuideAnchor.wrap(
                _anchor(_guideTypeKey, l10n.guideAttConfirmTypeTitle,
                    l10n.guideAttConfirmTypeDesc),
                Row(
                  children: [
                    Expanded(
                      child: _PunchTypeChip(
                        label: l10n.clockIn,
                        selected: primaryIsIn,
                        color: const Color(0xFF2E7D32),
                        onTap: () => setState(() => _selectedPunchType = 'in'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PunchTypeChip(
                        label: l10n.clockOut,
                        selected: !primaryIsIn,
                        color: Colors.orange,
                        onTap: () => setState(() => _selectedPunchType = 'out'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            GuideAnchor.wrap(
              _anchor(_guideLocationKey, l10n.guideAttConfirmLocationTitle,
                  l10n.guideAttConfirmLocationDesc),
              Text(
                l10n.attendanceLocationCheckHint,
                style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            if (_isSubmitting)
              const LoadingWidget()
            else
              ButtonGlobalWithoutIcon(
                guideAnchor: _confirmIsNoop
                    ? null
                    : _anchor(_guideConfirmKey, l10n.guideAttConfirmButtonTitle,
                        l10n.guideAttConfirmButtonDesc,
                        radius: BorderRadius.circular(8)),
                buttontext: _isQrOnceMode
                    ? l10n.checkInForToday
                    : AttendanceFormat.punchLabel(_selectedPunchType, l10n),
                buttonDecoration: kButtonDecoration.copyWith(
                  color: primaryIsIn ? const Color(0xFF2E7D32) : Colors.orange,
                ),
                buttonTextColor: kWhite,
                onPressed:
                    (r.checkedInToday && _isQrOnceMode) ? () {} : _submit,
              ),
            if (!_isQrOnceMode &&
                r.suggestClockIn != (_selectedPunchType == 'in')) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _selectedPunchType = r.suggestedAction;
                  }),
                  child: Text(
                    l10n.useSuggestedPunch(
                      AttendanceFormat.punchLabel(r.suggestedAction, l10n),
                    ),
                    style: kTextStyle.copyWith(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }
}

class _PunchTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PunchTypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.15) : kWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : kBorderColorTextField,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: kTextStyle.copyWith(
                color: selected ? color : kSubTitleColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
