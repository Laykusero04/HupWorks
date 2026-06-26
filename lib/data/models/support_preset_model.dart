/// Who should see a support FAQ preset.
enum SupportPresetAudience {
  all,
  client,
  seller,
}

/// A preset question and answer shown before live support chat.
class SupportPreset {
  final String question;
  final String answer;
  final SupportPresetAudience audience;

  const SupportPreset({
    required this.question,
    required this.answer,
    this.audience = SupportPresetAudience.all,
  });
}
