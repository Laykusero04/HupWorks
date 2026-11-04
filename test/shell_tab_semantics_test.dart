import 'dart:ui' show SemanticsRole, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/router/app_router.dart';

void main() {
  testWidgets('only the open shell tab is selected', (tester) async {
    final handle = tester.ensureSemantics();

    Future<void> expectOnlyOpenTab(List<String> labels, int openIndex) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: debugShellBottomNav(
              currentIndex: openIndex,
              labels: labels,
            ),
          ),
        ),
      );

      for (var i = 0; i < labels.length; i++) {
        final node = tester.getSemantics(find.bySemanticsLabel(labels[i]));
        expect(node.role, SemanticsRole.tab, reason: labels[i]);
        expect(
          node.flagsCollection.isSelected == Tristate.isTrue,
          i == openIndex,
          reason: labels[i],
        );
      }
    }

    await expectOnlyOpenTab(
      const ['Home', 'Message', 'Find Jobs', 'Contracts'],
      2,
    );
    await expectOnlyOpenTab(
      const ['Home', 'Message', 'Talent', 'Jobs', 'Contracts'],
      0,
    );

    handle.dispose();
  });
}
