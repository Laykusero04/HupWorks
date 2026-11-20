import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/seller_skills_editor.dart';
import 'package:freelancer/screen/widgets/skill_picker_field.dart';

import '../../../support/pd_harness.dart';

/// T-0172 fix round 3: the freelancer skills editor uses the seller teal (not
/// the client orange) for the number badge, tinted fill/border and Add buttons.
void main() {
  setUpAll(pdSetUp);

  testWidgets('seller skills editor: no orange on cards, badge or Add buttons',
      (t) async {
    await pdPump(
      t,
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SellerSkillsEditor(
            skills: const [SellerSkill(name: 'Barista', stars: 5)],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final en = lookupAppLocalizations(const Locale('en'));
    expect(find.text('Barista'), findsOneWidget);

    final avatar = t.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.backgroundColor, kSecondaryFill);

    final material = t.widget<Material>(find
        .ancestor(of: find.text('Barista'), matching: find.byType(Material))
        .first);
    expect(material.color, kSellerPrimary.withValues(alpha: 0.06));

    final buttons = find.byWidgetPredicate((w) => w is OutlinedButton);
    expect(buttons, findsWidgets);
    for (final e in buttons.evaluate()) {
      final b = e.widget as OutlinedButton;
      final fg = b.style!.foregroundColor!.resolve({});
      final side = b.style!.side!.resolve({})!;
      expect(fg, kSecondaryText);
      expect(side.color, kSellerPrimary.withValues(alpha: 0.4));
    }
    expect(find.text(en.skillAdd), findsWidgets);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('SkillSlotTile keeps the client orange by default', (t) async {
    await pdPump(
      t,
      Scaffold(
        body: SkillSlotTile(index: 1, name: 'Barista', onTap: () {}),
      ),
    );
    expect(t.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
        kPrimaryFill);
  });
}
