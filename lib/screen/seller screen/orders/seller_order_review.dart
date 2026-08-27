import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/interactive_star_rating.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();

  int _stars = 0;
  XFile? _pickedImage;
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

  Future<void> _openImagePicker() async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.removePhoto,
                    style: kTextStyle.copyWith(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'remove') {
      setState(() => _pickedImage = null);
      return;
    }

    final source =
        action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 2000, imageQuality: 88);
      if (file != null && mounted) setState(() => _pickedImage = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenPicker('$e'))),
        );
      }
    }
  }

  Widget _pickedImagePreview() {
    final x = _pickedImage;
    if (x == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconlyBold.camera, color: kLightNeutralColor, size: 32),
          const SizedBox(height: 6),
          Text(
            context.l10n.tapToAdd,
            style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
          ),
        ],
      );
    }
    if (kIsWeb) {
      return Image.network(
        x.path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Image.file(
      File(x.path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
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
                  ? () {}
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
                    const SizedBox(height: 24),
                    Text(
                      l10n.uploadImageOptional,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: kDarkWhite,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _openImagePicker,
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _pickedImagePreview(),
                              if (_pickedImage != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Material(
                                    color: Colors.black54,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                      onPressed: () =>
                                          setState(() => _pickedImage = null),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
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
