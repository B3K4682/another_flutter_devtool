import 'dart:convert';
import 'dart:io';

import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:another_flutter_devtool/src/tools/network_usage/network_usage_overrides_io.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

void main() {
  group('formatBytes', () {
    test('uses B, KB, MB and GB', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1023), '1023 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1024 * 1024), '1.0 MB');
      expect(formatBytes(5 * 1024 * 1024 * 1024), '5.0 GB');
      expect(formatBytes(2048 * 1024 * 1024 * 1024), '2048.0 GB');
    });
  });

  group('NetworkUsageTracker', () {
    test('aggregates totals and ranks hosts by received bytes', () {
      final tracker = NetworkUsageTracker(notifyInterval: Duration.zero);
      addTearDown(tracker.dispose);

      tracker
        ..recordRequest('a.com')
        ..recordSent('a.com', 100)
        ..recordReceived('a.com', 300)
        ..recordRequest('b.com')
        ..recordRequest('b.com')
        ..recordReceived('b.com', 900)
        ..recordRequest('c.com');

      final stats = tracker.stats;
      expect(stats.requestCount, 4);
      expect(stats.bytesSent, 100);
      expect(stats.bytesReceived, 1200);
      expect(stats.total, 1300);
      expect(stats.topHosts().map((host) => host.host), ['b.com', 'a.com', 'c.com']);
      expect(stats.topHosts(1).single.requests, 2);

      tracker.reset();
      expect(tracker.stats.requestCount, 0);
      expect(tracker.stats.hosts, isEmpty);
    });

    test('throttles notifications', () async {
      final tracker = NetworkUsageTracker(notifyInterval: const Duration(milliseconds: 20));
      addTearDown(tracker.dispose);
      var notifications = 0;
      tracker.addListener(() => notifications++);

      for (var i = 0; i < 50; i++) {
        tracker.recordReceived('a.com', 10);
      }
      expect(notifications, 0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifications, 1);
    });
  });

  group('TrackingHttpClient', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await request.drain<void>();
        request.response.write('x' * 5000);
        await request.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('counts request, sent and received bytes', () async {
      final tracker = NetworkUsageTracker(notifyInterval: Duration.zero);
      addTearDown(tracker.dispose);

      await HttpOverrides.runWithHttpOverrides(() async {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse('http://127.0.0.1:${server.port}/upload'));
        request.add(utf8.encode('y' * 2000));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        client.close();
        expect(body.length, 5000);
      }, NetworkUsageHttpOverrides(tracker));

      final stats = tracker.stats;
      expect(stats.requestCount, 1);
      expect(stats.bytesSent, greaterThan(2000));
      expect(stats.bytesReceived, greaterThan(5000));
      expect(stats.hosts.keys, ['127.0.0.1']);
    });
  });

  group('NetworkUsageCard', () {
    testWidgets('shows totals and top hosts, and resets', (tester) async {
      final tracker = NetworkUsageTracker(notifyInterval: Duration.zero);
      addTearDown(tracker.dispose);
      tracker
        ..recordRequest('api.example.com')
        ..recordSent('api.example.com', 512)
        ..recordReceived('api.example.com', 2048);

      await pumpDevtool(
        tester,
        sections: [
          GeneralSection(
            appInfo: const AppInfoTool(source: StaticAppInfoSource(testAppInfo)),
            networkUsage: NetworkUsageTool(tracker: tracker),
          ),
        ],
      );
      await openPanel(tester);
      await openSection(tester, GeneralSection.sectionId);
      final resetButton = find.byKey(DevtoolKeys.networkUsageResetButton);
      await tester.scrollUntilVisible(
        resetButton,
        100,
        scrollable: find
            .descendant(
              of: find.byKey(DevtoolKeys.sectionPage(GeneralSection.sectionId)),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();

      expect(find.byKey(DevtoolKeys.toolCard(NetworkUsageTool.toolId)), findsOneWidget);
      expect(find.text('Internet Data Usage'), findsOneWidget);
      expect(find.text('2.0 KB'), findsNWidgets(2));
      expect(find.text('512 B'), findsOneWidget);
      expect(find.text('2.5 KB'), findsOneWidget);
      expect(find.text('api.example.com'), findsOneWidget);

      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('No requests yet'), findsOneWidget);
      expect(find.text('0 B'), findsNWidgets(3));
    });

    testWidgets('can be hidden', (tester) async {
      await pumpDevtool(
        tester,
        sections: const [GeneralSection(appInfo: AppInfoTool(source: StaticAppInfoSource(testAppInfo)), networkUsage: null)],
      );
      await openPanel(tester);
      await openSection(tester, GeneralSection.sectionId);

      expect(find.byKey(DevtoolKeys.toolCard(NetworkUsageTool.toolId)), findsNothing);
    });
  });
}
