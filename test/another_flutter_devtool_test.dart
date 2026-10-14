import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _screenSize = Size(400, 800);

class _CounterApp extends StatefulWidget {
  const _CounterApp();

  @override
  State<_CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<_CounterApp> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => setState(() => _count++),
            child: Text('count: $_count'),
          ),
        ),
      ),
    );
  }
}

Future<void> _pump(WidgetTester tester, DevtoolConfig config) async {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AnotherFlutterDevtool(config: config, child: const _CounterApp()));
}

const _enabled = DevtoolConfig(enabled: true);

void main() {
  testWidgets('disabled config renders only the child', (tester) async {
    await _pump(tester, const DevtoolConfig(enabled: false));

    expect(find.text('count: 0'), findsOneWidget);
    expect(find.byKey(DevtoolKeys.launcher), findsNothing);
  });

  testWidgets('launcher disabled hides the launcher', (tester) async {
    await _pump(tester, const DevtoolConfig(enabled: true, launcher: LauncherConfig(enabled: false)));

    expect(find.byKey(DevtoolKeys.launcher), findsNothing);
  });

  testWidgets('launcher not initially visible hides the launcher', (tester) async {
    await _pump(tester, const DevtoolConfig(enabled: true, launcher: LauncherConfig(initiallyVisible: false)));

    expect(find.byKey(DevtoolKeys.launcher), findsNothing);
  });

  testWidgets('launcher is 36x36 with 8px radius and code icon', (tester) async {
    await _pump(tester, _enabled);

    expect(tester.getSize(find.byKey(DevtoolKeys.launcher)), const Size(36, 36));

    final container = tester.widget<Container>(
      find.descendant(of: find.byKey(DevtoolKeys.launcher), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(
      find.descendant(of: find.byKey(DevtoolKeys.launcher), matching: find.byIcon(Icons.code_rounded)),
      findsOneWidget,
    );
  });

  testWidgets('tapping launcher opens panel and close button dismisses it', (tester) async {
    await _pump(tester, _enabled);

    await tester.tap(find.byKey(DevtoolKeys.launcher));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.panel), findsOneWidget);
    expect(tester.getSize(find.byKey(DevtoolKeys.panel)), _screenSize);
    expect(find.byKey(DevtoolKeys.launcher), findsNothing);

    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.panel), findsNothing);
    expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);
  });

  testWidgets('system back closes the panel', (tester) async {
    await _pump(tester, _enabled);

    await tester.tap(find.byKey(DevtoolKeys.launcher));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.panel), findsNothing);
    expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);
  });

  testWidgets('dragging moves the launcher', (tester) async {
    await _pump(tester, _enabled);

    final start = tester.getTopLeft(find.byKey(DevtoolKeys.launcher));
    await tester.drag(find.byKey(DevtoolKeys.launcher), const Offset(-16, 200));
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(find.byKey(DevtoolKeys.launcher));

    expect(end - start, const Offset(-16, 200));
  });

  testWidgets('dragging far outside the screen clamps the launcher', (tester) async {
    await _pump(tester, _enabled);

    await tester.drag(find.byKey(DevtoolKeys.launcher), const Offset(-5000, 5000));
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byKey(DevtoolKeys.launcher));
    expect(rect.left, 0);
    expect(rect.bottom, _screenSize.height);

    await tester.drag(find.byKey(DevtoolKeys.launcher), const Offset(5000, -5000));
    await tester.pumpAndSettle();

    final moved = tester.getRect(find.byKey(DevtoolKeys.launcher));
    expect(moved.right, _screenSize.width);
    expect(moved.top, 0);
  });

  testWidgets('launcher keeps its position after the panel is closed', (tester) async {
    await _pump(tester, _enabled);

    await tester.drag(find.byKey(DevtoolKeys.launcher), const Offset(-100, 100));
    await tester.pumpAndSettle();
    final dropped = tester.getTopLeft(find.byKey(DevtoolKeys.launcher));

    await tester.tap(find.byKey(DevtoolKeys.launcher));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(DevtoolKeys.launcher)), dropped);
  });

  testWidgets('app underneath stays interactive', (tester) async {
    await _pump(tester, _enabled);

    await tester.tap(find.text('count: 0'));
    await tester.pump();

    expect(find.text('count: 1'), findsOneWidget);
  });
}
