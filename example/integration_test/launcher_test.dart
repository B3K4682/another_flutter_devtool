import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:another_flutter_devtool_example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final launcher = find.byKey(DevtoolKeys.launcher);
  final panel = find.byKey(DevtoolKeys.panel);

  Future<void> startApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
  }

  testWidgets('launcher is visible on startup', (tester) async {
    await startApp(tester);

    expect(launcher, findsOneWidget);
    expect(tester.getSize(launcher), const Size(36, 36));
  });

  testWidgets('dragging moves the launcher and it stays inside the screen', (tester) async {
    await startApp(tester);

    final start = tester.getTopLeft(launcher);
    await tester.drag(launcher, const Offset(-16, 160));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(launcher), start + const Offset(-16, 160));

    await tester.drag(launcher, const Offset(-10000, 10000));
    await tester.pumpAndSettle();
    final screen = tester.getRect(find.byType(app.ExampleApp));
    final rect = tester.getRect(launcher);
    expect(screen.contains(rect.topLeft), isTrue);
    expect(screen.contains(rect.bottomRight - const Offset(1, 1)), isTrue);
  });

  testWidgets('tapping the launcher opens a full-screen panel, close dismisses it', (tester) async {
    await startApp(tester);

    await tester.tap(launcher);
    await tester.pumpAndSettle();

    expect(panel, findsOneWidget);
    expect(tester.getSize(panel), tester.getSize(find.byType(app.ExampleApp)));
    expect(launcher, findsNothing);

    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(panel, findsNothing);
    expect(launcher, findsOneWidget);
  });

  testWidgets('system back closes the panel without popping the app', (tester) async {
    await startApp(tester);

    await tester.tap(launcher);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(panel, findsNothing);
    expect(find.byType(app.CounterPage), findsOneWidget);
  });

  testWidgets('app stays interactive with the launcher on top', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('increment_button')));
    await tester.pumpAndSettle();

    expect(find.text('Count: 1'), findsOneWidget);
  });
}
