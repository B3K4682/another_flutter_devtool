import 'dart:convert';
import 'dart:io';

import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:another_flutter_devtool/src/core/http/devtool_http_overrides_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late NetworkRecorder recorder;

  setUp(() async {
    recorder = NetworkRecorder(notifyInterval: Duration.zero, maxBodyBytes: 1024);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final response = request.response;
      switch (request.uri.path) {
        case '/echo':
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode({'received': body}));
        case '/missing':
          response.statusCode = HttpStatus.notFound;
          response.write('nope');
        case '/image':
          response.headers.contentType = ContentType('image', 'png');
          response.add(List.filled(4000, 1));
        case '/large':
          response.write('x' * 5000);
      }
      await response.close();
    });
  });

  tearDown(() async {
    recorder.dispose();
    await server.close(force: true);
  });

  Future<T> withRecorder<T>(Future<T> Function(HttpClient client) body) => HttpOverrides.runWithHttpOverrides(
        () async {
          final client = HttpClient();
          try {
            return await body(client);
          } finally {
            client.close(force: true);
          }
        },
        DevtoolHttpOverrides(observers: [recorder]),
      );

  Future<String> send(HttpClient client, String method, String path, {String? body}) async {
    final request = await client.openUrl(method, Uri.parse('http://127.0.0.1:${server.port}$path'));
    request.headers.set('X-Test', 'yes');
    if (body != null) request.write(body);
    final response = await request.close();
    return response.transform(utf8.decoder).join();
  }

  test('records request and response of a POST', () async {
    await withRecorder((client) => send(client, 'POST', '/echo?page=2', body: 'hello'));

    final call = recorder.calls.single;
    expect(call.method, 'POST');
    expect(call.uri.path, '/echo');
    expect(call.queryParameters, {
      'page': ['2'],
    });
    expect(call.state, NetworkCallState.completed);
    expect(call.statusCode, 200);
    expect(call.statusGroup, NetworkStatusGroup.success);
    expect(call.duration, isNotNull);
    expect(call.requestHeaders['x-test'], ['yes']);
    expect(call.requestBody.text, 'hello');
    expect(call.requestSize, 5);
    expect(call.responseHeaders['content-type']!.single, contains('application/json'));
    expect(jsonDecode(call.responseBody.text!), {'received': 'hello'});
  });

  test('groups client errors', () async {
    await withRecorder((client) => send(client, 'GET', '/missing'));

    final call = recorder.calls.single;
    expect(call.statusCode, 404);
    expect(call.statusGroup, NetworkStatusGroup.clientError);
    expect(call.responseBody.text, 'nope');
  });

  test('records connection errors as failed', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    await withRecorder((client) async {
      await expectLater(client.getUrl(Uri.parse('http://127.0.0.1:$port/')), throwsA(isA<SocketException>()));
    });

    final call = recorder.calls.single;
    expect(call.state, NetworkCallState.failed);
    expect(call.statusGroup, NetworkStatusGroup.failed);
    expect(call.statusCode, isNull);
    expect(call.error, isA<SocketException>());
    expect(call.stackTrace, isNotNull);
  });

  test('skips binary bodies and truncates long ones', () async {
    await withRecorder((client) async {
      await send(client, 'GET', '/image');
      await send(client, 'GET', '/large');
    });

    final [large, image] = recorder.calls;
    expect(image.responseBody.binary, isTrue);
    expect(image.responseBody.text, isNull);
    expect(image.responseSize, 4000);
    expect(large.responseBody.truncated, isTrue);
    expect(large.responseBody.text!.length, 1024);
    expect(large.responseSize, 5000);
  });

  test('ignores calls while paused', () async {
    recorder.setPaused(true);
    await withRecorder((client) => send(client, 'GET', '/echo'));
    expect(recorder.calls, isEmpty);

    recorder.setPaused(false);
    await withRecorder((client) => send(client, 'GET', '/echo'));
    expect(recorder.calls, hasLength(1));
  });

  test('keeps the newest maxCalls calls', () {
    final small = NetworkRecorder(maxCalls: 3, notifyInterval: Duration.zero);
    addTearDown(small.dispose);
    for (var id = 1; id <= 5; id++) {
      small.add(NetworkCall(id: id, method: 'GET', uri: Uri.parse('https://a.com/$id'), startedAt: DateTime(2026)));
    }
    expect(small.calls.map((call) => call.id), [5, 4, 3]);
  });

  test('restores cleared calls next to newer ones', () {
    for (var id = 1; id <= 2; id++) {
      recorder.add(NetworkCall(id: id, method: 'GET', uri: Uri.parse('https://a.com/$id'), startedAt: DateTime(2026)));
    }
    final removed = recorder.clear();
    expect(recorder.calls, isEmpty);

    recorder.add(NetworkCall(id: 3, method: 'GET', uri: Uri.parse('https://a.com/3'), startedAt: DateTime(2026)));
    recorder.restore(removed);
    expect(recorder.calls.map((call) => call.id), [3, 2, 1]);
  });
}
