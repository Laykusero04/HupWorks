import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/report_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerReport extends StatefulWidget {
  const SellerReport({
    Key? key,
    this.reportedUserId,
    this.initialContentUrl,
  }) : super(key: key);

  /// When reporting from chat/order, pass the other user's id.
  final String? reportedUserId;
  final String? initialContentUrl;

  @override
  State<SellerReport> createState() => _SellerReportState();
}

class _SellerReportState extends State<SellerReport> {
  final _contentUrlController = TextEditingController();
  final _detailsController = TextEditingController();

  late String _selectedReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = L10nLabels.reportCodes.first;
    if (widget.initialContentUrl != null) {
      _contentUrlController.text = widget.initialContentUrl!;
    }
  }

  @override
  void dispose() {
    _contentUrlController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  DropdownButton<String> _reasonDropdown(AppLocalizations l10n) {
    return DropdownButton<String>(
      icon: const Icon(FeatherIcons.chevronDown),
      items: L10nLabels.reportCodes
          .map((code) => DropdownMenuItem(
                value: code,
                child: Text(L10nLabels.reportReason(l10n, code)),
              ))
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
    setState(() => _isSubmitting = true);
    try {
      await ReportService.createReport(
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason,
        details: _detailsController.text,
        contentUrl: _contentUrlController.text,
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
          l10n.report,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
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
              buttontext: _isSubmitting ? l10n.sending : l10n.send,
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
              children: [
                const SizedBox(height: 30.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: l10n.reportWhyQuestion,
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: _reasonDropdown(l10n)),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _contentUrlController,
                  keyboardType: TextInputType.url,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: l10n.reportOriginalContentUrl,
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: l10n.reportEnterPostUrl,
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _detailsController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
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
