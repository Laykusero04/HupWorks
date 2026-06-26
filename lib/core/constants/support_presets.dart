import 'package:freelancer/data/models/support_preset_model.dart';

/// Static FAQ presets for Help & Support. Filter by role at display time.
abstract final class SupportPresets {
  static const List<SupportPreset> all = [
    SupportPreset(
      question: 'What is the difference between Messages and Help & Support?',
      answer:
          'Messages is for chatting with clients or sellers about jobs and orders. '
          'Help & Support is for contacting the HupWorks team about account, payment, '
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
      question: 'How do I add money to my wallet?',
      audience: SupportPresetAudience.client,
      answer:
          'Open the profile menu → Deposit → Add Deposit. After adding funds, '
          'you can use your wallet balance when placing orders or hiring freelancers.',
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
          'Profile menu → Seller Report. Describe the issue and submit. '
          'For urgent problems, also start a live chat with our support team.',
    ),
    SupportPreset(
      question: 'How do I apply to a job?',
      audience: SupportPresetAudience.seller,
      answer:
          'Go to Find Jobs, open a listing, and submit your offer with price and '
          'delivery details. The client can accept and start an order from there.',
    ),
    SupportPreset(
      question: 'How do I withdraw my earnings?',
      audience: SupportPresetAudience.seller,
      answer:
          'Profile menu → Withdrawals → Withdraw Money. Add a payment method first '
          'under Payment Methods if you have not already.',
    ),
    SupportPreset(
      question: 'How does attendance check-in work?',
      audience: SupportPresetAudience.seller,
      answer:
          'Profile menu → Attendance. At the job site, scan the QR code provided '
          'by the client to punch in or out for that order.',
    ),
    SupportPreset(
      question: 'How do I add a payment method?',
      audience: SupportPresetAudience.seller,
      answer:
          'Profile menu → Payment Methods. Add PayPal, card, or other supported '
          'methods so you can receive withdrawals.',
    ),
    SupportPreset(
      question: 'When will I get paid for a completed order?',
      audience: SupportPresetAudience.seller,
      answer:
          'After the client marks the order complete and any review period passes, '
          'earnings are added to your wallet. Withdraw from Profile → Withdrawals.',
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
