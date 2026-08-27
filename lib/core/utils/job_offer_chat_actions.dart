import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/onboarding/hire_onboarding_editor_screen.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../screen/widgets/constant.dart';

/// Shared hire / reject / counter-offer actions for job applications in chat.
class JobOfferChatActions {
  JobOfferChatActions._();

  static Future<void> rejectOffer(
    BuildContext context, {
    required String offerId,
    VoidCallback? onComplete,
  }) async {
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
    final sellerName = seller?['name'] ?? 'this freelancer';
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
      bodyText =
          "Accept $sellerName's offer ($priceLabel)? The job stays open so you can hire more freelancers until you close it.";
    } else if (fillsAll) {
      bodyText =
          "Accept $sellerName's offer ($priceLabel)? This fills your last hire spot (${accepted + 1} of $cap). "
          'The job will close to new applicants.';
    } else {
      final remaining = cap - accepted - 1;
      bodyText =
          "Accept $sellerName's offer ($priceLabel)? After this hire you will have $remaining more open spot${remaining == 1 ? '' : 's'} "
          '(${accepted + 1} of $cap filled).';
    }

    final l10n = context.l10n;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fillsAll
                ? 'Hired! This job is now full and closed to new applicants.'
                : 'Hired! Contract created.',
          ),
          action: SnackBarAction(
            label: l10n.openContract,
            onPressed: () => _openOnboardingIfNeeded(context, orderId),
          ),
        ),
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

  static Future<void> _openOnboardingIfNeeded(
    BuildContext context,
    String orderId,
  ) async {
    try {
      final packet = await HireOnboardingService.getPacketForOrder(orderId);
      if (!context.mounted) return;
      await HireOnboardingEditorScreen(orderId: orderId).launch(context);
      if (packet == null && context.mounted) {
        // Editor opened for new draft; no extra action needed.
      }
    } catch (_) {
      // Non-blocking — hire already succeeded.
    }
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
