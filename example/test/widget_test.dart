import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:another_flutter_devtool_example/main.dart';
import 'package:another_flutter_devtool_example/my_custom_tool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app renders with the devtool launcher', (tester) async {
    await tester.pumpWidget(const AnotherFlutterDevtool(config: DevtoolConfig(enabled: true), child: ExampleApp()));

    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  });

  testWidgets('the custom section hosts the registered custom tool', (tester) async {
    DevtoolTools.register(const MyCustomTool());
    addTearDown(DevtoolTools.clear);

    await tester.pumpWidget(
      AnotherFlutterDevtool(
        config: DevtoolConfig(
          enabled: true,
          sections: const [GeneralSection(), playgroundSection],
          storage: InMemoryDevtoolStorage(),
        ),
        child: const ExampleApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DevtoolKeys.launcher));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DevtoolKeys.sectionCard(playgroundSection.id)));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.toolCard('my_custom_tool')), findsOneWidget);
    expect(find.text('It works'), findsOneWidget);
  });
}
