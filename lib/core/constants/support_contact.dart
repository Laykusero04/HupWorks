/// Public support contact for HupWorks.
class SupportContact {
  SupportContact._();

  static const email = 'support@hup-works.nl';
  static final Uri mailtoUri = Uri(
    scheme: 'mailto',
    path: email,
  );
}
