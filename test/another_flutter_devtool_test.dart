import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

void main() {
  final launcher = find.byKey(DevtoolKeys.launcher);
  final panel = find.byKey(DevtoolKeys.panel);

  testWidgets('disabled config renders only the child', (tester) async {
    await pumpDevtool(tester, enabled: false);

    expect(find.text('count: 0'), findsOneWidget);
    expect(launcher, findsNothing);
  });

  testWidgets('launcher disabled hides the launcher', (tester) async {
    await pumpDevtool(tester, launcher: const LauncherConfig(enabled: false));

    expect(launcher, findsNothing);
  });

  testWidgets('launcher not initially visible hides the launcher', (tester) async {
    await pumpDevtool(tester, launcher: const LauncherConfig(initiallyVisible: false));

    expect(launcher, findsNothing);
  });

  testWidgets('launcher is 36x36 with 8px radius and code icon', (tester) async {
    await pumpDevtool(tester);

    expect(tester.getSize(launcher), const Size(36, 36));

    final container = tester.widget<Container>(find.descendant(of: launcher, matching: find.byType(Container)).first);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(decoration.color, DevtoolColors.primary);
    expect(find.descendant(of: launcher, matching: find.byIcon(Icons.code_rounded)), findsOneWidget);
  });

  testWidgets('tapping launcher opens panel and close button dismisses it', (tester) async {
    await pumpDevtool(tester);

    await openPanel(tester);

    expect(panel, findsOneWidget);
    expect(tester.getSize(panel), testScreenSize);
    expect(launcher, findsNothing);

    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(panel, findsNothing);
    expect(launcher, findsOneWidget);
  });

  testWidgets('system back closes the panel', (tester) async {
    await pumpDevtool(tester);

    await openPanel(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(panel, findsNothing);
    expect(launcher, findsOneWidget);
  });

  testWidgets('dragging moves the launcher', (tester) async {
    await pumpDevtool(tester);

    final start = tester.getTopLeft(launcher);
    await tester.drag(launcher, const Offset(150, 200));
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(launcher);

    expect(end - start, const Offset(150, 200));
  });

  testWidgets('dragging far outside the screen clamps the launcher', (tester) async {
    await pumpDevtool(tester);

    await tester.drag(launcher, const Offset(-5000, 5000));
    await tester.pumpAndSettle();

    final rect = tester.getRect(launcher);
    expect(rect.left, 0);
    expect(rect.bottom, testScreenSize.height);

    await tester.drag(launcher, const Offset(5000, -5000));
    await tester.pumpAndSettle();

    final moved = tester.getRect(launcher);
    expect(moved.right, testScreenSize.width);
    expect(moved.top, 0);
  });

  testWidgets('launcher keeps its position after the panel is closed', (tester) async {
    await pumpDevtool(tester);

    await tester.drag(launcher, const Offset(100, 100));
    await tester.pumpAndSettle();
    final dropped = tester.getTopLeft(launcher);

    await openPanel(tester);
    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(launcher), dropped);
  });

  testWidgets('app underneath stays interactive', (tester) async {
    await pumpDevtool(tester);

    await tester.tap(find.text('count: 0'));
    await tester.pump();

    expect(find.text('count: 1'), findsOneWidget);
  });
}
