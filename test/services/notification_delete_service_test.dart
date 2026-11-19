import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/services/notification_service.dart';
import 'package:http/http.dart' as http;

import '../support/qa_supabase.dart';

/// T-0168: delete requests must always be scoped to the signed-in user's id.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requests = <http.Request>[];
  Object? returnedRows = [
    {'id': 'x'}
  ];

  setUpAll(() async {
    await initQaSupabase(
      signedIn: true,
      tables: {
        'notifications': (request) {
          requests.add(request);
          return returnedRows;
        },
      },
    );
  });

  setUp(() {
    requests.clear();
    returnedRows = [
      {'id': 'x'}
    ];
  });

  test('deleteNotification sends DELETE filtered by id AND user_id', () async {
    await NotificationService.deleteNotification('notif-123');

    expect(requests, hasLength(1));
    final r = requests.single;
    expect(r.method, 'DELETE');
    expect(r.url.path, endsWith('/rest/v1/notifications'));
    expect(r.url.queryParameters['id'], 'eq.notif-123');
    expect(r.url.queryParameters['user_id'], 'eq.$qaSignedInUserId');
  });

  test('deleteAllNotifications sends DELETE filtered by user_id only',
      () async {
    await NotificationService.deleteAllNotifications();

    expect(requests, hasLength(1));
    final r = requests.single;
    expect(r.method, 'DELETE');
    expect(r.url.path, endsWith('/rest/v1/notifications'));
    expect(r.url.queryParameters['user_id'], 'eq.$qaSignedInUserId');
    expect(r.url.queryParameters.containsKey('id'), isFalse);
  });

  test('deleteNotification asks for the deleted rows and fails on 0 rows',
      () async {
    returnedRows = <Object?>[];
    await expectLater(
        NotificationService.deleteNotification('n1'), throwsException);
    expect(requests.single.url.queryParameters['select'], 'id');
  });

  test('deleteAllNotifications returns the number of deleted rows', () async {
    returnedRows = [
      {'id': 'a'},
      {'id': 'b'}
    ];
    expect(await NotificationService.deleteAllNotifications(), 2);
    returnedRows = <Object?>[];
    expect(await NotificationService.deleteAllNotifications(), 0);
  });
}
