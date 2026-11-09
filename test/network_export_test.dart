import 'dart:convert';

import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter_test/flutter_test.dart';

NetworkCall _call() => NetworkCall(
  id: 7,
  method: 'POST',
  uri: Uri.parse('https://api.example.com/posts?tag=a&tag=b'),
  startedAt: DateTime(2026, 10, 22, 20, 11, 5),
  state: NetworkCallState.completed,
  duration: const Duration(milliseconds: 223),
  requestHeaders: const {
    'authorization': ['Bearer secret'],
    'content-type': ['application/json'],
    'content-length': ['13'],
  },
  requestBody: const NetworkBody(text: '{"it\'s": "ok"}'),
  requestSize: 13,
  statusCode: 201,
  reasonPhrase: 'Created',
  responseHeaders: const {
    'set-cookie': ['a=1', 'b=2'],
  },
  responseBody: const NetworkBody(text: '{"id": 1}'),
  responseSize: 9,
);

void main() {
  test('exports calls as JSON with redacted headers', () {
    final json = jsonDecode(exportCallsJson([_call()], exportedAt: DateTime(2026))) as Map<String, Object?>;

    expect(json['count'], 1);
    final call = (json['calls']! as List).single as Map<String, Object?>;
    expect(call['method'], 'POST');
    expect(call['status'], 201);
    expect(call['durationMs'], 223);

    final request = call['request']! as Map<String, Object?>;
    expect(request['query'], {
      'tag': ['a', 'b'],
    });
    expect(request['headers'], containsPair('authorization', '[redacted]'));
    expect(request['headers'], containsPair('content-type', 'application/json'));
    expect(request['body'], {"it's": 'ok'});

    final response = call['response']! as Map<String, Object?>;
    expect(response['headers'], {'set-cookie': '[redacted]'});
    expect(response['body'], {'id': 1});
    expect(call['error'], isNull);
  });

  test('redaction can be turned off', () {
    final json = jsonDecode(exportCallJson(_call(), redactedHeaders: const {})) as Map<String, Object?>;
    final request = json['request']! as Map<String, Object?>;
    expect(request['headers'], containsPair('authorization', 'Bearer secret'));
  });

  test('masks sensitive query parameters in the url and query', () {
    final call = NetworkCall(
      id: 1,
      method: 'GET',
      uri: Uri.parse('https://api.example.com/me?Access_Token=abc&page=2&access_token=def'),
      startedAt: DateTime(2026),
    );
    final json = jsonDecode(exportCallJson(call)) as Map<String, Object?>;

    expect(json['url'], 'https://api.example.com/me?Access_Token=[redacted]&page=2&access_token=[redacted]');
    final request = json['request']! as Map<String, Object?>;
    expect(request['query'], {'Access_Token': '[redacted]', 'page': '2', 'access_token': '[redacted]'});
  });

  test('redactUrl keeps urls without sensitive parameters unchanged', () {
    final uri = Uri.parse('https://api.example.com/posts?tag=a%20b#top');
    expect(redactUrl(uri, defaultRedactedQueryParameters), uri.toString());
    expect(
      redactUrl(Uri.parse('https://x.dev/a?token=1#top'), defaultRedactedQueryParameters),
      'https://x.dev/a?token=[redacted]#top',
    );
  });

  test('builds a cURL command', () {
    expect(
      toCurl(_call()),
      "curl \\\n"
      "  -X POST \\\n"
      "  'https://api.example.com/posts?tag=a&tag=b' \\\n"
      "  -H 'authorization: Bearer secret' \\\n"
      "  -H 'content-type: application/json' \\\n"
      "  --data-raw '{\"it'\\''s\": \"ok\"}'",
    );
  });

  test('formats durations', () {
    expect(formatDuration(const Duration(milliseconds: 223)), '223 ms');
    expect(formatDuration(const Duration(milliseconds: 1240)), '1.24 s');
    expect(formatDuration(const Duration(seconds: 63)), '1m 3s');
  });
}
