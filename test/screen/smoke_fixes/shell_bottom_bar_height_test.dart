// Regression (T-0170 round 2 device check): a Center / Container alignment in
// the bottom-nav tile took all the height the Scaffold offered, so the bar
// filled half the screen and hid every page. Earlier tests gave the bar a
// tight height and missed it. Here the bar sits in a real Scaffold with the
// loose height a phone gives it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/router/app_router.dart';

void main() {
  const seller = ['Home', 'Berichten', 'Vacatures', 'Overeenkomsten'];
  const client = ['Home', 'Berichten', 'Talent', 'Jobs', 'Overeenkomsten'];

  for (final size in const [Size(375, 812), Size(402, 874), Size(440, 956)]) {
    for (final labels in const [seller, client]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (var selected = 0; selected < labels.length; selected++) {
          testWidgets(
              'bar stays compact: ${size.width.toInt()}pt '
              '${labels.length} tabs x$scale selected=$selected',
              (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MaterialApp(
                home: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      body: const ColoredBox(
                        key: ValueKey('body'),
                        color: Colors.white,
                        child: SizedBox.expand(),
                      ),
                      bottomNavigationBar: debugShellBottomNav(
                        currentIndex: selected,
                        labels: labels,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            final body = tester.getSize(find.byKey(const ValueKey('body')));
            // The page must keep most of the screen; the bar is a strip.
            expect(body.height, greaterThan(size.height * 0.7),
                reason: 'bottom bar ballooned (body ${body.height})');
          });
        }
      }
    }
  }
}
