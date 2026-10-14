import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:another_flutter_devtool_example/main.dart' as app;
import 'package:another_flutter_devtool_example/my_custom_tool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final launcher = find.byKey(DevtoolKeys.launcher);
  final badge = find.byKey(DevtoolKeys.versionBadge);
  final generalCard = find.byKey(DevtoolKeys.sectionCard(GeneralSection.sectionId));
  final appInfoCard = find.byKey(DevtoolKeys.toolCard(AppInfoTool.toolId));
  final toggle = find.byType(Switch);

  Future<void> openAppInfo(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(launcher);
    await tester.pumpAndSettle();
    await tester.tap(generalCard);
    await tester.pumpAndSettle();
  }

  /// Reads the value rendered on the right-hand side of an info row.
  String valueOf(WidgetTester tester, String label) {
    final row = find.ancestor(of: find.text(label), matching: find.byType(DevtoolInfoRow));
    final value = find.descendant(of: row, matching: find.byType(SelectableText));
    return tester.widget<SelectableText>(value).data!;
  }

  testWidgets('the General section lists the App Information card', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(launcher);
    await tester.pumpAndSettle();

    expect(generalCard, findsOneWidget);
    expect(find.text('General'), findsOneWidget);

    await tester.tap(generalCard);
    await tester.pumpAndSettle();

    expect(appInfoCard, findsOneWidget);
    expect(find.text('App Information'), findsOneWidget);
  });

  testWidgets('the app section shows its registered tool', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(launcher);
    await tester.pumpAndSettle();

    final playgroundCard = find.byKey(DevtoolKeys.sectionCard(playgroundSection.id));
    expect(playgroundCard, findsOneWidget);

    await tester.tap(playgroundCard);
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.toolCard('my_custom_tool')), findsOneWidget);
    expect(find.text('It works'), findsOneWidget);
  });

  testWidgets('real values are collected from the platform', (tester) async {
    await openAppInfo(tester);

    expect(valueOf(tester, 'App version'), isNotEmpty);
    expect(valueOf(tester, 'App version'), contains('('));
    expect(valueOf(tester, 'Device model'), isNot('Unknown'));
    expect(valueOf(tester, 'OS version'), isNot('Unknown'));
    expect(valueOf(tester, 'Current flavor'), 'Debug');
    expect(valueOf(tester, 'App startup time'), isNot('Measuring...'));
  });

  testWidgets('the info modal describes the card and dismisses', (tester) async {
    await openAppInfo(tester);

    await tester.tap(find.byKey(DevtoolKeys.toolInfoButton(AppInfoTool.toolId)));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.infoModal), findsOneWidget);

    await tester.tap(find.byKey(DevtoolKeys.infoModalCloseButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.infoModal), findsNothing);
    expect(appInfoCard, findsOneWidget);
  });

  testWidgets('toggling the switch shows or hides the version badge', (tester) async {
    await openAppInfo(tester);

    final wasOn = tester.widget<Switch>(toggle).value;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, !wasOn);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(badge, wasOn ? findsNothing : findsOneWidget);

    // Restore the stored value so the suite stays order independent.
    await tester.tap(launcher);
    await tester.pumpAndSettle();
    await tester.tap(generalCard);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(toggle).value, wasOn);
  });
}
