import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/screen/widgets/verification_submit_bar.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final enabled in [false, true]) {
      testWidgets('bar sizes to content at scale $scale enabled=$enabled',
          (t) async {
        await t.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                size: const Size(375, 800),
                textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              appBar: AppBar(title: const Text('Identity')),
              body: const Center(child: Text('score card body')),
              bottomNavigationBar: VerificationSubmitBar(
                label: 'Indienen ter beoordeling',
                enabled: enabled,
                onPressed: () {},
                enabledColor: Colors.teal,
              ),
            ),
          ),
        ));
        expect(t.takeException(), isNull);
        expect(find.text('score card body'), findsOneWidget);
        final bar = t.getSize(find.byType(VerificationSubmitBar));
        expect(bar.height, lessThan(120));
        expect(bar.height, greaterThanOrEqualTo(48));
        final body = t.getSize(find.text('score card body'));
        expect(body.height, greaterThan(0));
      });
    }
  }
}
