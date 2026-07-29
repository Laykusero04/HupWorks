import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/legal_document_screen.dart';

class ClientAbout extends StatelessWidget {
  const ClientAbout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LegalDocumentScreen(
      appBarTitle: l10n.aboutUs,
      sections: [
        (title: l10n.aboutHupWorksTitle, body: l10n.aboutHupWorksBody),
      ],
    );
  }
}
