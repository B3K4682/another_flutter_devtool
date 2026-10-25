import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

NetworkCall _call(int id, String method, String url, {int? status, Object? error, int ms = 120}) => NetworkCall(
  id: id,
  method: method,
  uri: Uri.parse(url),
  startedAt: DateTime(2026, 10, 22, 20, 11, id),
  state: error == null ? NetworkCallState.completed : NetworkCallState.failed,
  duration: Duration(milliseconds: ms),
  requestHeaders: const {
    'accept': ['application/json'],
  },
  statusCode: status,
  reasonPhrase: status == null ? null : 'Reason',
  responseHeaders: const {
    'content-type': ['application/json'],
  },
  responseBody: status == null ? NetworkBody.empty : const NetworkBody(text: '{"ok":true}'),
  error: error,
  stackTrace: error == null ? null : StackTrace.current,
);

Future<NetworkRecorder> _pumpNetwork(WidgetTester tester) async {
  final recorder = NetworkRecorder(notifyInterval: Duration.zero);
  addTearDown(recorder.dispose);
  recorder
    ..add(_call(1, 'GET', 'https://api.example.com/planets?id=1', status: 200))
    ..add(_call(2, 'POST', 'https://api.example.com/planets', status: 201))
    ..add(_call(3, 'GET', 'https://api.example.com/missing', status: 404))
    ..add(_call(4, 'DELETE', 'https://api.example.com/planets/1', status: 500, ms: 1500))
    ..add(_call(5, 'GET', 'https://down.example.com/', error: 'SocketException: Connection refused'));

  await pumpDevtool(
    tester,
    sections: [
      testGeneralSection,
      NetworkSection(recorder: recorder),
    ],
  );
  await openPanel(tester);
  await openSection(tester, NetworkSection.sectionId);
  return recorder;
}

String _countText(WidgetTester tester) => tester.widget<Text>(find.byKey(DevtoolKeys.networkCallCount)).data!;

void main() {
  testWidgets('lists calls with status, method, url and duration', (tester) async {
    await _pumpNetwork(tester);

    expect(find.byKey(DevtoolKeys.networkCallsPage), findsOneWidget);
    expect(_countText(tester), '5 calls');
    expect(find.text('api.example.com/planets?id=1'), findsOneWidget);
    expect(find.text('404'), findsOneWidget);
    expect(find.text('ERR'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);
    expect(find.text('1.50 s'), findsOneWidget);
  });

  testWidgets('filters by search terms and status chips', (tester) async {
    await _pumpNetwork(tester);

    await tester.enterText(find.byKey(DevtoolKeys.networkSearchField), 'get planets');
    await tester.pumpAndSettle();
    expect(_countText(tester), '1 of 5 calls');
    expect(find.byKey(DevtoolKeys.networkCallRow(1)), findsOneWidget);

    await tester.enterText(find.byKey(DevtoolKeys.networkSearchField), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(DevtoolKeys.networkStatusFilter('failed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DevtoolKeys.networkStatusFilter('failed')));
    await tester.pumpAndSettle();
    expect(_countText(tester), '1 of 5 calls');
    expect(find.byKey(DevtoolKeys.networkCallRow(5)), findsOneWidget);
    expect(find.byKey(DevtoolKeys.networkStatusFilter('3xx')), findsNothing);
  });

  testWidgets('clears calls and undoes it', (tester) async {
    await _pumpNetwork(tester);

    await tester.tap(find.byKey(DevtoolKeys.networkClearButton));
    await tester.pumpAndSettle();
    expect(_countText(tester), '0 calls');
    expect(find.text('No calls yet'), findsOneWidget);
    expect(find.text('Cleared 5 calls'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_countText(tester), '5 calls');
  });

  testWidgets('pauses recording', (tester) async {
    final recorder = await _pumpNetwork(tester);

    await tester.tap(find.byKey(DevtoolKeys.networkPauseButton));
    await tester.pumpAndSettle();
    expect(recorder.isPaused, isTrue);
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('shows request, response and copies cURL', (tester) async {
    await _pumpNetwork(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.tap(find.byKey(DevtoolKeys.networkCallRow(1)));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.networkCallDetails), findsOneWidget);
    expect(find.text('https://api.example.com/planets?id=1'), findsOneWidget);
    expect(find.text('QUERY PARAMETERS'), findsOneWidget);
    expect(find.text('accept'), findsOneWidget);
    expect(find.text('Error'), findsNothing);

    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();
    expect(find.text('200 Reason'), findsOneWidget);
    expect(find.textContaining('"ok": true'), findsOneWidget);

    await tester.tap(find.byKey(DevtoolKeys.networkCopyCurlButton));
    await tester.pumpAndSettle();
    expect(copied, contains("'https://api.example.com/planets?id=1'"));
    expect(find.text('cURL copied'), findsOneWidget);
  });

  testWidgets('opens failed calls on the error tab', (tester) async {
    await _pumpNetwork(tester);

    await tester.tap(find.byKey(DevtoolKeys.networkCallRow(5)));
    await tester.pumpAndSettle();

    expect(find.text('SocketException: Connection refused'), findsOneWidget);
    expect(find.text('STACK TRACE'), findsOneWidget);
  });
}
