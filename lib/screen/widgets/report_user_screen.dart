import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/report_service.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

/// Shared marketplace report form for clients and freelancers.
class ReportUserScreen extends StatefulWidget {
  const ReportUserScreen({
    super.key,
    this.reportedUserId,
    this.reportedUserName,
    this.jobPostId,
    this.jobTitle,
    this.orderId,
    this.title,
  });

  final String? reportedUserId;
  final String? reportedUserName;
  final String? jobPostId;
  final String? jobTitle;
  final String? orderId;
  final String? title;

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  final _detailsController = TextEditingController();

  late String _selectedReason;
  bool _isSubmitting = false;

  bool get _hasUserContext =>
      (widget.reportedUserId?.trim().isNotEmpty ?? false) ||
      (widget.reportedUserName?.trim().isNotEmpty ?? false);

  bool get _hasJobContext =>
      (widget.jobPostId?.trim().isNotEmpty ?? false) ||
      (widget.jobTitle?.trim().isNotEmpty ?? false);

  bool get _hasOrderContext => widget.orderId?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _selectedReason = L10nLabels.reportCodes.first;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  DropdownButton<String> _reasonDropdown(AppLocalizations l10n) {
    return DropdownButton<String>(
      isExpanded: true,
      icon: const Icon(FeatherIcons.chevronDown),
      items: L10nLabels.reportCodes
          .map(
            (code) => DropdownMenuItem(
              value: code,
              child: Text(
                L10nLabels.reportReason(l10n, code),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      value: _selectedReason,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: _isSubmitting
          ? null
          : (value) {
              if (value == null) return;
              setState(() => _selectedReason = value);
            },
    );
  }

  Future<void> _handleSend() async {
    final details = _detailsController.text.trim();
    if (details.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reportDetailsTooShort)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ReportService.createReport(
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason,
        details: details,
        jobPostId: widget.jobPostId,
        orderId: widget.orderId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reportSubmitted)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _contextBanner(AppLocalizations l10n) {
    if (!_hasUserContext && !_hasJobContext && !_hasOrderContext) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kDarkWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorderColorTextField),
        ),
        child: Text(
          l10n.reportOpenFromContextHint,
          style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasUserContext)
            _contextLine(
              Icons.person_outline,
              l10n.reportReportingUser(
                widget.reportedUserName?.trim().isNotEmpty == true
                    ? widget.reportedUserName!.trim()
                    : l10n.authRoleClient,
              ),
            ),
          if (_hasJobContext) ...[
            if (_hasUserContext) const SizedBox(height: 8),
            _contextLine(
              Icons.work_outline,
              l10n.reportReportingJob(
                widget.jobTitle?.trim().isNotEmpty == true
                    ? widget.jobTitle!.trim()
                    : 'Job',
              ),
            ),
          ],
          if (_hasOrderContext) ...[
            if (_hasUserContext || _hasJobContext) const SizedBox(height: 8),
            _contextLine(
              Icons.receipt_long_outlined,
              l10n.reportReportingContract,
            ),
          ],
        ],
      ),
    );
  }

  Widget _contextLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          widget.title ?? l10n.report,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: ButtonGlobalWithoutIcon(
                  buttontext: l10n.cancel,
                  buttonDecoration: kButtonDecoration.copyWith(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(color: redColor),
                  ),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  buttonTextColor: redColor,
                ),
              ),
              Expanded(
                child: ButtonGlobalWithoutIcon(
                  buttontext: _isSubmitting ? l10n.sending : l10n.submitReport,
                  buttonDecoration: kButtonDecoration.copyWith(
                    color: _isSubmitting ? kLightNeutralColor : kPrimaryColor,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  onPressed: _isSubmitting ? null : _handleSend,
                  buttonTextColor: kWhite,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0),
                _contextBanner(l10n),
                const SizedBox(height: 20.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          borderSide: BorderSide(
                            color: kBorderColorTextField,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: l10n.reportWhyQuestion,
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: _reasonDropdown(l10n),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _detailsController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 4,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.done,
                  decoration: kInputDecoration.copyWith(
                    labelText: l10n.reportAdditionalInfo,
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: l10n.reportEnterInformation,
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  l10n.reportDetailsHelp,
                  style: kTextStyle.copyWith(
                    color: kLightNeutralColor,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
