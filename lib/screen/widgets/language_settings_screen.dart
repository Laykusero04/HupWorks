import 'package:flutter/material.dart';
import 'package:freelancer/core/locale/locale_scope.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

/// Shared language settings (client + seller). Only locales with ARB files.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  static final _options = <({Locale locale, String Function(AppLocalizations) label})>[
    (locale: const Locale('en'), label: (l) => l.languageEnglish),
    (locale: const Locale('nl'), label: (l) => l.languageDutch),
    (locale: const Locale('bn'), label: (l) => l.languageBengali),
  ];

  @override
  Widget build(BuildContext context) {
    final localeController = LocaleScope.of(context);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          context.l10n.language,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: ListenableBuilder(
            listenable: localeController,
            builder: (context, _) {
              final l10n = context.l10n;
              return Column(
                children: [
                  const SizedBox(height: 30.0),
                  ListView.builder(
                    itemCount: _options.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (_, i) {
                      final option = _options[i];
                      final selected = localeController.isSelected(option.locale);
                      return ListTile(
                        onTap: () async {
                          await localeController.setLocale(option.locale);
                          if (!context.mounted) return;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.languageChanged)),
                            );
                          });
                        },
                        visualDensity: const VisualDensity(vertical: -3),
                        horizontalTitleGap: 10,
                        contentPadding: const EdgeInsets.only(bottom: 15),
                        title: Text(
                          option.label(l10n),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: kTextStyle.copyWith(color: kNeutralColor),
                        ),
                        trailing: Icon(
                          selected ? Icons.check : null,
                          color: kPrimaryColor,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
