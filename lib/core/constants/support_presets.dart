import 'package:freelancer/data/models/support_preset_model.dart';

/// Static FAQ presets for Help & Support. Filter by role at display time.
abstract final class SupportPresets {
  static const List<SupportPreset> all = [
    SupportPreset(
      question: 'What is the difference between Messages and Help & Support?',
      answer:
          'Messages is for chatting with clients or sellers about jobs and orders. '
          'Help & Support is for contacting the HupWorks team about account, '
          'or technical issues.',
    ),
    SupportPreset(
      question: 'How do I reset my password?',
      answer:
          'On the login screen, tap Forgot Password and enter your email. '
          'Check your inbox for a reset link from HupWorks.',
    ),
    SupportPreset(
      question: 'How do I update my profile?',
      answer:
          'Open the menu (profile icon) → My Profile. You can update your name, '
          'photo, and other details from there.',
    ),
    SupportPreset(
      question: 'How do I post a job?',
      audience: SupportPresetAudience.client,
      answer:
          'From the client home screen, use Post a Job (or the jobs section). '
          'Fill in the title, category, location, budget, and requirements, then publish.',
    ),
    SupportPreset(
      question: 'How do I track my order?',
      audience: SupportPresetAudience.client,
      answer:
          'Go to the Orders tab to see active, pending, and completed work. '
          'Tap an order for details, delivery status, and chat with the seller.',
    ),
    SupportPreset(
      question: 'How do I message a seller?',
      audience: SupportPresetAudience.client,
      answer:
          'Open an order or job offer and use Message, or go to the Messages tab '
          'to see all conversations with sellers.',
    ),
    SupportPreset(
      question: 'How do I report a seller?',
      audience: SupportPresetAudience.client,
      answer:
          'Open the chat, contract, or freelancer profile and tap Report. '
          'Choose a reason, describe what happened, and submit. '
          'For urgent problems, also start a live chat with support.',
    ),
    SupportPreset(
      question: 'How do payments work?',
      audience: SupportPresetAudience.client,
      answer:
          'Payment happens outside the app (cash, bank transfer, or local e-wallet). '
          'Agree on the amount in the job or chat, then pay the freelancer directly '
          'after the work is done.',
    ),
    SupportPreset(
      question: 'How do I report a client or job?',
      audience: SupportPresetAudience.seller,
      answer:
          'Open the job, contract, or chat and tap the report (flag) icon. '
          'Choose a reason, describe what happened, and submit. '
          'You can also use Report in your profile menu.',
    ),
    SupportPreset(
      question: 'How do I apply to a job?',
      audience: SupportPresetAudience.seller,
      answer:
          'Go to Find Jobs, open a listing, and submit your offer with price and '
          'delivery details. The client can accept and start an order from there.',
    ),
    SupportPreset(
      question: 'How do I get paid?',
      audience: SupportPresetAudience.seller,
      answer:
          'HupWorks does not hold or transfer money. After you finish the work, '
          'collect payment directly from the client (cash, bank transfer, or local '
          'e-wallet) based on the agreed amount.',
    ),
    SupportPreset(
      question: 'How does attendance check-in work?',
      audience: SupportPresetAudience.seller,
      answer:
          'Profile menu → Attendance. At the job site, scan the QR code provided '
          'by the client to punch in or out for that order.',
    ),
  ];

  static List<SupportPreset> forRole(String? role) {
    if (role == 'client') {
      return all
          .where((p) =>
              p.audience == SupportPresetAudience.all ||
              p.audience == SupportPresetAudience.client)
          .toList();
    }
    if (role == 'seller') {
      return all
          .where((p) =>
              p.audience == SupportPresetAudience.all ||
              p.audience == SupportPresetAudience.seller)
          .toList();
    }
    return all.where((p) => p.audience == SupportPresetAudience.all).toList();
  }
}
