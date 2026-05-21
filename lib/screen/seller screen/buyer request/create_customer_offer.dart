import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

enum _MessageType { success, error, warning }

enum _OfferSubmitMode { agreePosted, customBid }

class CreateCustomerOffer extends StatefulWidget {
  final String jobPostId;
  final String jobTitle;
  final Object? budgetMin;
  final Object? budgetMax;
  final Object? budgetBasis;

  const CreateCustomerOffer({
    Key? key,
    required this.jobPostId,
    required this.jobTitle,
    this.budgetMin,
    this.budgetMax,
    this.budgetBasis,
  }) : super(key: key);

  @override
  State<CreateCustomerOffer> createState() => _CreateCustomerOfferState();
}

class _CreateCustomerOfferState extends State<CreateCustomerOffer> {
  final _amountController = TextEditingController();
  final _coverLetterController = TextEditingController();
  String _priceBasis = JobPostsService.budgetBasisFixed;
  bool _isSubmitting = false;

  late final bool _hasPostedBudget;
  late _OfferSubmitMode _mode;

  Map<String, dynamic> get _jobPostBudgetMap => {
        'budget_min': widget.budgetMin,
        'budget_max': widget.budgetMax,
        'budget_basis': widget.budgetBasis,
      };

  @override
  void initState() {
    super.initState();
    _hasPostedBudget = JobPostsService.hasPostedBudget(_jobPostBudgetMap);
    _mode = _hasPostedBudget ? _OfferSubmitMode.agreePosted : _OfferSubmitMode.customBid;
    final agreed = JobPostsService.agreedOfferFromJobPost(_jobPostBudgetMap);
    if (agreed != null) {
      _priceBasis = agreed.basis;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {required _MessageType type}) {
    final Color bg;
    final IconData icon;
    final String title;
    switch (type) {
      case _MessageType.success:
        bg = kPrimaryColor;
        icon = Icons.check_circle_outline;
        title = 'Success';
        break;
      case _MessageType.error:
        bg = const Color(0xFFDC2626);
        icon = Icons.error_outline;
        title = 'Something went wrong';
        break;
      case _MessageType.warning:
        bg = const Color(0xFFF59E0B);
        icon = Icons.info_outline;
        title = 'Heads up';
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 6,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(icon, color: kWhite, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: kTextStyle.copyWith(
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: kTextStyle.copyWith(color: kWhite, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _handleSubmit() async {
    final bool agreed = _mode == _OfferSubmitMode.agreePosted;
    double? amount;
    String basis = _priceBasis;

    if (agreed) {
      final posted = JobPostsService.agreedOfferFromJobPost(_jobPostBudgetMap);
      if (posted == null) {
        _showMessage(
          'This job has no posted rate to agree to. Enter a custom amount instead.',
          type: _MessageType.warning,
        );
        return;
      }
      amount = posted.price;
      basis = posted.basis;
    } else {
      amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        _showMessage('Please enter a valid offer amount', type: _MessageType.warning);
        return;
      }
      basis = _priceBasis;
    }

    setState(() => _isSubmitting = true);

    try {
      await SellerOrdersService.createOffer(
        jobPostId: widget.jobPostId,
        price: amount,
        priceBasis: basis,
        coverLetter: _coverLetterController.text.trim().isNotEmpty
            ? _coverLetterController.text.trim()
            : null,
        agreedToPostedRate: agreed,
      );

      if (mounted) {
        _showMessage(
          agreed ? 'Application sent at client\'s posted rate' : 'Your offer has been sent',
          type: _MessageType.success,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showMessage(e.toString(), type: _MessageType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _modeChip({
    required String label,
    required _OfferSubmitMode mode,
    required IconData icon,
  }) {
    final selected = _mode == mode;
    return Expanded(
      child: Material(
        color: selected ? kPrimaryColor.withValues(alpha: 0.1) : kWhite,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _isSubmitting ? null : () => setState(() => _mode = mode),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? kPrimaryColor : kBorderColorTextField,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? kPrimaryColor : kLightNeutralColor, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: kTextStyle.copyWith(
                    color: selected ? kPrimaryColor : kSubTitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomLift = MediaQuery.paddingOf(context).bottom + 16;
    final postedLabel = JobPostsService.formatBudgetRange(
      widget.budgetMin,
      widget.budgetMax,
      widget.budgetBasis,
    );
    final agreed = JobPostsService.agreedOfferFromJobPost(_jobPostBudgetMap);
    final isAgree = _mode == _OfferSubmitMode.agreePosted;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Submit offer',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Material(
        color: kWhite,
        elevation: 12,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomLift),
          child: ButtonGlobalWithoutIcon(
            buttontext: _isSubmitting
                ? 'Sending…'
                : isAgree
                    ? 'Apply at client\'s rate'
                    : 'Submit offer',
            buttonDecoration: kButtonDecoration.copyWith(
              color: _isSubmitting ? kLightNeutralColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: _isSubmitting ? null : _handleSubmit,
            buttonTextColor: kWhite,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
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
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: kDarkWhite,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, color: kPrimaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.jobTitle,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                if (_hasPostedBudget) ...[
                  Row(
                    children: [
                      _modeChip(
                        label: 'Agree to\nclient\'s rate',
                        mode: _OfferSubmitMode.agreePosted,
                        icon: Icons.handshake_outlined,
                      ),
                      const SizedBox(width: 10),
                      _modeChip(
                        label: 'Custom\nbid',
                        mode: _OfferSubmitMode.customBid,
                        icon: Icons.edit_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (isAgree && postedLabel.isNotEmpty) ...[
                  Text(
                    'You are applying without a counter-offer. The client sees your application at their posted rate.',
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client\'s posted rate',
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          postedLabel,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (agreed != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Your application: ${JobPostsService.formatOfferAmountLine(agreed.price, agreed.basis)}',
                            style: kTextStyle.copyWith(
                              color: kPrimaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    _hasPostedBudget
                        ? 'Enter your own amount if you want to bid differently from the client\'s budget.'
                        : 'This job has no posted budget — enter the amount you are asking for.',
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (_hasPostedBudget && postedLabel.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Client posted: $postedLabel',
                      style: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          cursorColor: kNeutralColor,
                          decoration: kInputDecoration.copyWith(
                            labelText: 'Your offer amount',
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                            hintText: 'Enter your bid',
                            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 118,
                        child: InputDecorator(
                          decoration: kInputDecoration.copyWith(
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(
                                color: kBorderColorTextField,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsetsDirectional.only(
                              start: 10,
                              end: 4,
                              top: 0,
                              bottom: 0,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: 'Quote as',
                            labelStyle: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontSize: 12,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              isDense: true,
                              icon: const Icon(
                                FeatherIcons.chevronDown,
                                size: 18,
                                color: kSubTitleColor,
                              ),
                              value: _priceBasis,
                              style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontSize: 13,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: JobPostsService.budgetBasisFixed,
                                  child: Text('Total', style: kTextStyle.copyWith(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: JobPostsService.budgetBasisPerHour,
                                  child: Text('/ hour', style: kTextStyle.copyWith(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: JobPostsService.budgetBasisPerDay,
                                  child: Text('/ day', style: kTextStyle.copyWith(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: JobPostsService.budgetBasisPerMonth,
                                  child: Text('/ month', style: kTextStyle.copyWith(fontSize: 13)),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _priceBasis = v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _coverLetterController,
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  maxLines: 5,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Message (optional)',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Optional note for the client…',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: bottomLift + 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
