import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test-only Supabase harness (QA, T-0121/T-0128).
///
/// Supabase points at a non-resolvable host and every REST call goes through a
/// MockClient, so no request leaves the test process. All ids and emails are
/// fake. Routing is by table / rpc name.

const qaSignedInUserId = '00000000-0000-4000-8000-000000000001';
const qaSellerId = '00000000-0000-4000-8000-000000000002';

/// A handler returns the JSON body for one table or rpc. Return null for "no rows".
typedef QaHandler = Object? Function(http.Request request);

String _b64Url(Map<String, Object?> json) => base64Url
    .encode(utf8.encode(jsonEncode(json)))
    .replaceAll('=', '');

/// Session JSON for a signed-in test user that does not expire during the run.
String qaSessionJson() {
  final exp = DateTime.now().toUtc().add(const Duration(hours: 10));
  final expSec = exp.millisecondsSinceEpoch ~/ 1000;
  final jwt = [
    _b64Url({'alg': 'HS256', 'typ': 'JWT'}),
    _b64Url({
      'sub': qaSignedInUserId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'exp': expSec,
    }),
    'qasignature',
  ].join('.');
  return jsonEncode({
    'access_token': jwt,
    'token_type': 'bearer',
    'expires_in': 36000,
    'expires_at': expSec,
    'refresh_token': 'qa-refresh-token',
    'user': {
      'id': qaSignedInUserId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'qa-user@example.invalid',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  });
}

class _QaSessionStorage extends LocalStorage {
  const _QaSessionStorage(this._session);
  final String? _session;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _session != null;

  @override
  Future<String?> accessToken() async => _session;

  @override
  Future<void> removePersistedSession() async {}

  @override
  Future<void> persistSession(String persistSessionString) async {}
}

/// http client that answers every request from [tables] in-process.
/// Sets `request` on each response, which postgrest needs (MockClient does not).
class _QaRouter extends http.BaseClient {
  _QaRouter(this.tables);
  final Map<String, QaHandler> tables;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final req = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    final res = _route(req);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }

  http.Response _route(http.Request request) {
    final segs = request.url.pathSegments;
    final name = segs.isEmpty ? '' : segs.last;
    final handler = tables[name];
    final wantsObject =
        (request.headers['accept'] ?? '').contains('vnd.pgrst.object');
    final body = handler == null ? null : handler(request);

    if (wantsObject) {
      if (body is List && body.length == 1) return _json(body.first);
      if (body is Map) return _json(body);
      return http.Response(
        jsonEncode({
          'code': 'PGRST116',
          'message': 'JSON object requested, multiple (or no) rows returned',
          'details': 'The result contains 0 rows',
          'hint': null,
        }),
        406,
        headers: {'content-type': 'application/json'},
      );
    }
    if (body is Map) return _json([body]);
    if (body is List) return _json(body);
    return _json(<Object?>[]);
  }
}

/// Initialises Supabase once per test file. [tables] maps a table or rpc name
/// to a handler. Unknown names behave like an empty table (PostgREST-style).
Future<void> initQaSupabase({
  required Map<String, QaHandler> tables,
  bool signedIn = false,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});

  final mock = _QaRouter(tables);

  await Supabase.initialize(
    url: 'https://qa-test.invalid',
    anonKey: 'qa-test-anon-key',
    httpClient: mock,
    debug: false,
    authOptions: FlutterAuthClientOptions(
      localStorage: _QaSessionStorage(signedIn ? qaSessionJson() : null),
      detectSessionInUri: false,
      autoRefreshToken: false,
    ),
  );
}

http.Response _json(Object? body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );

/// Rows for the seller edit form. [showAge] null means the column is absent.
Map<String, QaHandler> sellerEditTables({
  String? dateOfBirth = '1990-05-17',
  bool? showAge,
}) {
  return {
    'my_profile': (_) => {
          'id': qaSignedInUserId,
          'role': 'seller',
          'name': 'Sam Tester',
          'phone': '',
          'gender': 'Male',
          'email': 'qa-user@example.invalid',
          'city': 'Leiden',
          'country': 'NL',
        },
    'my_seller_profile': (_) => {
          'user_id': qaSignedInUserId,
          'job_title': 'Warehouse assistant',
          'about': 'QA test profile',
          'skills': <Object?>[],
          'languages': <Object?>[],
          if (showAge != null) 'show_age': showAge,
        },
    'seller_private_details': (_) => {
          'user_id': qaSignedInUserId,
          'date_of_birth': dateOfBirth,
          'street_address': null,
          'state': null,
          'postal_code': null,
        },
  };
}
