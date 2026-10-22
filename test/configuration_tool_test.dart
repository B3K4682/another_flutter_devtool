import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

Future<void> _openConfigurationCard(WidgetTester tester, {void Function(String route)? onNavigate}) async {
  await pumpDevtool(
    tester,
    sections: [
      GeneralSection(
        appInfo: const AppInfoTool(source: StaticAppInfoSource(testAppInfo)),
        configuration: ConfigurationTool(onNavigate: onNavigate),
      ),
    ],
  );
  await openPanel(tester);
  await openSection(tester, GeneralSection.sectionId);
  final goButton = find.byKey(DevtoolKeys.configurationGoButton);
  await tester.scrollUntilVisible(
    goButton,
    100,
    scrollable: find
        .descendant(
          of: find.byKey(DevtoolKeys.sectionPage(GeneralSection.sectionId)),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ConfigurationTool', () {
    testWidgets('closes the panel and navigates to the typed route', (tester) async {
      final routes = <String>[];
      await _openConfigurationCard(tester, onNavigate: routes.add);

      await tester.enterText(find.byKey(DevtoolKeys.configurationRouteField), ' /example ');
      await tester.tap(find.byKey(DevtoolKeys.configurationGoButton));
      await tester.pumpAndSettle();

      expect(routes, ['/example']);
      expect(find.byKey(DevtoolKeys.panel), findsNothing);
      expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);
    });

    testWidgets('adds a leading slash on submit', (tester) async {
      final routes = <String>[];
      await _openConfigurationCard(tester, onNavigate: routes.add);

      await tester.enterText(find.byKey(DevtoolKeys.configurationRouteField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();

      expect(routes, ['/test']);
    });

    testWidgets('ignores empty input', (tester) async {
      final routes = <String>[];
      await _openConfigurationCard(tester, onNavigate: routes.add);

      await tester.tap(find.byKey(DevtoolKeys.configurationGoButton));
      await tester.pumpAndSettle();

      expect(routes, isEmpty);
      expect(find.byKey(DevtoolKeys.sectionPage(GeneralSection.sectionId)), findsOneWidget);
    });

    testWidgets('is disabled without onNavigate', (tester) async {
      await _openConfigurationCard(tester);

      final field = tester.widget<EditableText>(
        find.descendant(of: find.byKey(DevtoolKeys.configurationRouteField), matching: find.byType(EditableText)),
      );
      expect(field.readOnly || !field.focusNode.canRequestFocus, isTrue);
      expect(find.textContaining('Pass ConfigurationTool(onNavigate: ...)'), findsOneWidget);
    });
  });
}
