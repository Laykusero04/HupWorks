import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/legal_document_screen.dart';

class Policy extends StatelessWidget {
  const Policy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LegalDocumentScreen(
      appBarTitle: l10n.privacyPolicy,
      sections: L10nLabels.privacySections(l10n),
    );
  }
}
