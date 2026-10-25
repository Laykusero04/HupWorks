import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/interactive_star_rating.dart';
import 'package:freelancer/services/orders_service.dart';

import '../../widgets/constant.dart';
import '../seller popUp/seller_popup.dart';

class SellerOrderReview extends StatefulWidget {
  final String orderId;
  final String clientId;

  /// Optional; set for service-based orders.
  final String? serviceId;

  /// Optional; set for job-offer orders.
  final String? jobOfferId;

  /// Shown in the header; falls back to a generic label if null.
  final String? clientName;

  /// Optional profile photo URL from `profiles.profile_image_url`.
  final String? clientProfileImageUrl;

  const SellerOrderReview({
    Key? key,
    required this.orderId,
    required this.clientId,
    this.serviceId,
    this.jobOfferId,
    this.clientName,
    this.clientProfileImageUrl,
  }) : super(key: key);

  @override
  State<SellerOrderReview> createState() => _SellerOrderReviewState();
}

class _SellerOrderReviewState extends State<SellerOrderReview> {
  final TextEditingController _feedbackController = TextEditingController();

  int _stars = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _showSuccessThenExit() async {
    await showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: const ReviewSubmittedPopUp(),
        );
      },
    );
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  String _displayClientName(AppLocalizations l10n) {
    final n = widget.clientName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return l10n.roleClient;
  }

  ImageProvider _clientAvatar() {
    final url = widget.clientProfileImageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return const AssetImage('images/profilepic2.png');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.writeReview,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: kWhite,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: ButtonGlobalWithoutIcon(
              buttontext: _isSubmitting ? l10n.publishing : l10n.publishReview,
              buttonDecoration: kButtonDecoration.copyWith(
                color: _isSubmitting ? kLightNeutralColor : kPrimaryColor,
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_stars <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(context.l10n.pleaseChooseStarRating)),
                        );
                        return;
                      }
                      setState(() => _isSubmitting = true);
                      try {
                        await OrdersService.submitSellerOrderReview(
                          orderId: widget.orderId,
                          clientId: widget.clientId,
                          rating: _stars,
                          comment: _feedbackController.text,
                          serviceId: widget.serviceId,
                          jobOfferId: widget.jobOfferId,
                        );
                        if (!context.mounted) return;
                        await _showSuccessThenExit();
                      } catch (e) {
                        if (!context.mounted) return;
                        final s = e.toString();
                        final duplicate = s.contains('23505') ||
                            s.contains('reviews_order_reviewer_unique');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              duplicate
                                  ? l10n.reviewAlreadySubmitted
                                  : l10n.couldNotPublishReview('$e'),
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              buttonTextColor: kWhite,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.reviewYourExperience,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.rateExperienceWithClient,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: kDarkWhite,
                            backgroundImage: _clientAvatar(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _displayClientName(l10n),
                            style: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.postedThisContract,
                            style: kTextStyle.copyWith(
                                color: kSubTitleColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.selectRating,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InteractiveStarRating(
                      value: _stars,
                      onChanged: (s) => setState(() => _stars = s),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _feedbackController,
                      keyboardType: TextInputType.multiline,
                      cursorColor: kNeutralColor,
                      minLines: 4,
                      maxLines: 8,
                      decoration: kInputDecoration.copyWith(
                        alignLabelWithHint: true,
                        labelText: l10n.yourFeedback,
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                        hintText: l10n.feedbackHint,
                        hintStyle:
                            kTextStyle.copyWith(color: kLightNeutralColor),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
