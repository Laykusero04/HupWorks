import 'package:flutter/material.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class HireOnboardingReaderScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? jobPost;

  const HireOnboardingReaderScreen({
    super.key,
    required this.orderId,
    this.jobPost,
  });

  @override
  State<HireOnboardingReaderScreen> createState() =>
      _HireOnboardingReaderScreenState();
}

class _HireOnboardingReaderScreenState extends State<HireOnboardingReaderScreen> {
  HireOnboardingPacket? _packet;
  bool _loading = true;
  bool _acking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final packet = await HireOnboardingService.getPacketForOrder(
        widget.orderId,
        sellerView: true,
      );
      if (mounted) {
        setState(() {
          _packet = packet;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _acknowledge() async {
    setState(() => _acking = true);
    try {
      await HireOnboardingService.acknowledge(widget.orderId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  List<HireOnboardingSection> get _visibleSections {
    final sections = _packet?.sections ?? [];
    return sections.where((s) => s.body.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showOnsiteHint =
        widget.jobPost != null && AttendanceService.isOnsiteJob(widget.jobPost);
    final acknowledged = _packet?.acknowledged ?? false;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.firstDayInstructions,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : _packet == null
              ? Center(
                  child: Text(
                    l10n.instructionsNotAvailable,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showOnsiteHint) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_scanner,
                                      color: Color(0xFF2E7D32),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        l10n.onboardingUseScanQrHint,
                                        style: kTextStyle.copyWith(
                                          color: kSubTitleColor,
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_visibleSections.isEmpty)
                              Text(
                                l10n.noSectionDetails,
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              )
                            else
                              ..._visibleSections.map((s) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Container(
                                    width: context.width(),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kWhite,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: kBorderColorTextField,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: kTextStyle.copyWith(
                                            color: kNeutralColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          s.body,
                                          style: kTextStyle.copyWith(
                                            color: kSubTitleColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    if (!acknowledged)
                      Material(
                        color: kWhite,
                        elevation: 8,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                          child: ButtonGlobalWithoutIcon(
                            buttontext: _acking
                                ? l10n.pleaseWaitEllipsis
                                : l10n.onboardingReadUnderstood,
                            buttonDecoration: kButtonDecoration.copyWith(
                              color: kPrimaryColor,
                            ),
                            onPressed: _acking ? () {} : _acknowledge,
                            buttonTextColor: kWhite,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.onboardingAcknowledgedLabel,
                              style: kTextStyle.copyWith(
                                color: kSubTitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
