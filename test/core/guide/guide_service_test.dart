import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<bool> seen(String uid, String role, String screen, [int v = 1]) =>
      GuideService.hasSeen(uid: uid, role: role, screenId: screen, version: v);

  test('markSeen writes key guide_seen_<uid>_<role>_<screen>_v<n>', () async {
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'client_home', version: 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'guide_seen_u1_client_client_home_v2'});
    expect(prefs.getBool('guide_seen_u1_client_client_home_v2'), true);
  });

  test('hasSeen false by default, true after markSeen, version-specific',
      () async {
    expect(await seen('u1', 'client', 'client_home'), false);
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'client_home', version: 1);
    expect(await seen('u1', 'client', 'client_home'), true);
    expect(await seen('u1', 'client', 'client_home', 2), false);
    expect(await seen('u2', 'client', 'client_home'), false);
    expect(await seen('u1', 'freelancer', 'client_home'), false);
  });

  test('resetAll removes only that uid+role', () async {
    SharedPreferences.setMockInitialValues({'other_key': 'x'});
    for (final a in [
      ['u1', 'client', 's1'],
      ['u1', 'client', 's2'],
      ['u1', 'freelancer', 's1'],
      ['u2', 'client', 's1'],
    ]) {
      await GuideService.markSeen(
          uid: a[0], role: a[1], screenId: a[2], version: 1);
    }
    await GuideService.resetAll(uid: 'u1', role: 'client');
    expect(await seen('u1', 'client', 's1'), false);
    expect(await seen('u1', 'client', 's2'), false);
    expect(await seen('u1', 'freelancer', 's1'), true);
    expect(await seen('u2', 'client', 's1'), true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('other_key'), 'x');
  });

  test('reset clears only that screen (all versions), uid and role', () async {
    for (final sc in ['a', 'b']) {
      await GuideService.markSeen(
          uid: 'u1', role: 'client', screenId: sc, version: 1);
    }
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'a', version: 2);
    await GuideService.markSeen(
        uid: 'u2', role: 'client', screenId: 'a', version: 1);
    await GuideService.markSeen(
        uid: 'u1', role: 'seller', screenId: 'a', version: 1);
    await GuideService.reset(uid: 'u1', role: 'client', screenId: 'a');
    expect(await seen('u1', 'client', 'a'), false);
    expect(await seen('u1', 'client', 'a', 2), false);
    expect(await seen('u1', 'client', 'b'), true);
    expect(await seen('u2', 'client', 'a'), true);
    expect(await seen('u1', 'seller', 'a'), true);
  });
}
