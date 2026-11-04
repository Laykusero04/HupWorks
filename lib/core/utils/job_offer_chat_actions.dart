import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/client%20screen/client%20orders/client_order_details.dart';
import 'package:freelancer/screen/onboarding/hire_onboarding_editor_screen.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../screen/widgets/constant.dart';

/// Shared hire / reject / counter-offer actions for job applications in chat.
class JobOfferChatActions {
  JobOfferChatActions._();

  static Future<void> rejectOffer(
    BuildContext context, {
    required String offerId,
    String? sellerName,
    VoidCallback? onComplete,
  }) async {
    final l10n = context.l10n;
    final name = sellerName?.trim().isNotEmpty == true
        ? sellerName!.trim()
        : l10n.thisFreelancer;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectApplicationTitle),
        content: Text(l10n.rejectApplicationConfirmBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.rejectApplication,
                style: kTextStyle.copyWith(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await JobPostsService.updateOfferStatus(offerId, 'rejected');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.applicationRejected)),
      );
      onComplete?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  static Future<void> acceptOffer(
    BuildContext context, {
    required Map<String, dynamic> offer,
    required List<Map<String, dynamic>> siblingOffers,
    VoidCallback? onComplete,
  }) async {
    final seller = offer['profiles'] as Map<String, dynamic>?;
    final l10n = context.l10n;
    final sellerName = seller?['name'] ?? l10n.thisFreelancer;
    final priceLabel = JobPostsService.formatOfferAmountShort(
      offer['price'],
      offer['price_basis'],
    );
    final jobPost = offer['job_posts'] as Map<String, dynamic>? ?? {};
    final accepted = JobPostsService.countAcceptedOffers(siblingOffers);
    final unlimited =
        JobPostsService.workersNeededIsUnlimited(jobPost['workers_needed']);
    final fillsAll = JobPostsService.acceptingFillsAllSlots(
      jobPost['workers_needed'],
      accepted,
    );
    final cap = JobPostsService.parseWorkersNeeded(jobPost['workers_needed']);

    final String bodyText;
    if (unlimited) {
      bodyText = l10n.hireConfirmUnlimited(sellerName.toString(), priceLabel);
    } else if (fillsAll) {
      bodyText = l10n.hireConfirmFillsAll(
        sellerName.toString(),
        priceLabel,
        accepted + 1,
        cap,
      );
    } else {
      final remaining = cap - accepted - 1;
      bodyText = l10n.hireConfirmRemaining(
        sellerName.toString(),
        priceLabel,
        remaining,
        accepted + 1,
        cap,
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hireFreelancerTitle),
        content: Text(bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.hireAction,
                style: kTextStyle.copyWith(
                    color: kPrimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final orderId =
          await JobPostsService.acceptJobOffer(offer['id'] as String);
      if (!context.mounted) return;
      final hiredJobPost = await _jobPostWithSite(jobPost);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fillsAll ? l10n.hiredJobFull : l10n.hiredContractCreated,
          ),
          action: SnackBarAction(
            label: l10n.openContract,
            onPressed: () {
              if (!context.mounted) return;
              ClientOrderDetails(orderId: orderId).launch(context);
            },
          ),
        ),
      );
      _showPostHireOnboardingSheet(
        context,
        orderId: orderId,
        jobPost: hiredJobPost,
      );
      onComplete?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  /// Inbox and chat offers only embed a short job post. Load the site fields
  /// the instructions editor needs when they were not selected with the offer.
  static Future<Map<String, dynamic>> _jobPostWithSite(
    Map<String, dynamic> jobPost,
  ) async {
    final id = jobPost['id']?.toString();
    if (id == null || id.isEmpty) return jobPost;
    if (jobPost.containsKey('location') &&
        jobPost.containsKey('location_type') &&
        jobPost.containsKey('attendance_mode')) {
      return jobPost;
    }
    try {
      final details = await JobPostsService.getJobPostDetails(id);
      return {...jobPost, ...details};
    } catch (_) {
      return jobPost;
    }
  }

  static void _showPostHireOnboardingSheet(
    BuildContext context, {
    required String orderId,
    required Map<String, dynamic> jobPost,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.addFirstDayInstructionsTitle,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.addFirstDayInstructionsBody,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                ButtonGlobalWithoutIcon(
                  buttontext: l10n.addInstructionsNow,
                  buttonDecoration:
                      kButtonDecoration.copyWith(color: kPrimaryColor),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    HireOnboardingEditorScreen(
                      orderId: orderId,
                      jobLocation: jobPost['location'] as String?,
                      jobLocationType: jobPost['location_type'] as String?,
                      attendanceMode:
                          AttendanceMode.effectiveForJobPost(jobPost),
                    ).launch(context);
                  },
                  buttonTextColor: kWhite,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n.sendLater,
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showCounterOfferDialog(
    BuildContext context, {
    required String conversationId,
    required String offerId,
    required Map<String, dynamic> offer,
    VoidCallback? onComplete,
  }) async {
    final amountController = TextEditingController(
      text: offer['price']?.toString() ?? '',
    );
    final noteController = TextEditingController();
    final l10n = context.l10n;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.counterOfferTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.counterOfferBody,
                style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.counterOfferAmountHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.counterOfferNoteHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );

    final amount = double.tryParse(amountController.text.trim());
    final note = noteController.text.trim();
    amountController.dispose();
    noteController.dispose();

    if (submitted != true || amount == null || amount <= 0) return;

    final jobPost = offer['job_posts'] as Map<String, dynamic>? ?? {};
    final title = jobPost['title'] as String? ?? 'this job';
    final basis =
        offer['price_basis'] as String? ?? JobPostsService.budgetBasisFixed;
    final formatted =
        JobPostsService.formatOfferAmountLine(amount, basis);

    final body = StringBuffer()
      ..writeln('💬 Counter offer for "$title"')
      ..writeln('Proposed amount: $formatted');
    if (note.isNotEmpty) {
      body
        ..writeln()
        ..writeln(note);
    }

    try {
      await JobPostsService.counterJobOffer(offerId: offerId, price: amount);
      await ChatService.sendMessage(
        conversationId: conversationId,
        content: body.toString().trim(),
        messageType: 'counter_offer',
        jobOfferId: offerId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.counterOfferSent)),
        );
        onComplete?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  static String formatOfferDisplay(Map<String, dynamic> offer) {
    final amount = JobPostsService.formatOfferAmountShort(
      offer['price'],
      offer['price_basis'],
    );
    final delivery = JobOfferDelivery.formatLabel(
      offer['delivery_time'],
      offer['delivery_time_unit'],
    );
    return '$amount · $delivery';
  }
}
