import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

void main() {
  final badge = find.byKey(DevtoolKeys.versionBadge);

  GeneralSection generalWith({bool showVersionBadgeByDefault = true, String? flavor}) => GeneralSection(
    appInfo: AppInfoTool(
      source: const StaticAppInfoSource(testAppInfo),
      flavor: flavor,
      showVersionBadgeByDefault: showVersionBadgeByDefault,
    ),
  );

  Future<void> openAppInfo(
    WidgetTester tester, {
    required DevtoolStorage storage,
    bool showVersionBadgeByDefault = true,
    String? flavor,
  }) async {
    await pumpDevtool(
      tester,
      storage: storage,
      sections: [generalWith(showVersionBadgeByDefault: showVersionBadgeByDefault, flavor: flavor)],
    );
    await openPanel(tester);
    await openSection(tester, GeneralSection.sectionId);
  }

  testWidgets('shows version, device, OS, flavor and startup time', (tester) async {
    await openAppInfo(tester, storage: InMemoryDevtoolStorage());

    expect(find.text('App version'), findsOneWidget);
    expect(find.text('1.2.3 (42)'), findsOneWidget);
    expect(find.text('Device model'), findsOneWidget);
    expect(find.text('Pixel 8'), findsOneWidget);
    expect(find.text('OS version'), findsOneWidget);
    expect(find.text('Android 15 (SDK 35)'), findsOneWidget);
    expect(find.text('Current flavor'), findsOneWidget);
    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('App startup time'), findsOneWidget);
    expect(find.text('412 ms'), findsOneWidget);
  });

  testWidgets('colors the flavor semantically', (tester) async {
    await openAppInfo(tester, storage: InMemoryDevtoolStorage());

    final flavor = tester.widget<SelectableText>(
      find.ancestor(of: find.text('Debug'), matching: find.byType(SelectableText)),
    );
    expect(flavor.style?.color, DevtoolColors.warning);
  });

  testWidgets('a custom flavor is shown without a semantic color', (tester) async {
    await openAppInfo(tester, storage: InMemoryDevtoolStorage(), flavor: 'Staging');

    final flavor = tester.widget<SelectableText>(
      find.ancestor(of: find.text('Staging'), matching: find.byType(SelectableText)),
    );
    expect(flavor.style?.color, DevtoolColors.textPrimary);
  });

  testWidgets('the toggle persists and shows the badge under the launcher', (tester) async {
    final storage = InMemoryDevtoolStorage();
    await openAppInfo(tester, storage: storage, showVersionBadgeByDefault: false);

    final toggle = find.byType(Switch);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(find.text('Show version below launcher'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(storage.getBool(DevtoolController.showVersionBadgeKey), isTrue);

    await closePanel(tester);

    expect(badge, findsOneWidget);
    expect(find.text('v1.2.3 (42)'), findsOneWidget);
  });

  testWidgets('a stored value wins over the tool default', (tester) async {
    final storage = InMemoryDevtoolStorage({DevtoolController.showVersionBadgeKey: false});

    await pumpDevtool(tester, storage: storage);

    expect(badge, findsNothing);
  });

  testWidgets('the badge shows by default and hides when toggled off', (tester) async {
    final storage = InMemoryDevtoolStorage();
    await pumpDevtool(tester, storage: storage);

    expect(badge, findsOneWidget);

    await openPanel(tester);
    await openSection(tester, GeneralSection.sectionId);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await closePanel(tester);

    expect(badge, findsNothing);
    expect(storage.getBool(DevtoolController.showVersionBadgeKey), isFalse);
  });

  testWidgets('no badge is shown without the app info tool', (tester) async {
    await pumpDevtool(tester, sections: const [GeneralSection(appInfo: null)]);

    expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);
    expect(badge, findsNothing);
  });

  testWidgets('the info modal explains the card', (tester) async {
    await openAppInfo(tester, storage: InMemoryDevtoolStorage());

    await tester.tap(find.byKey(DevtoolKeys.toolInfoButton(AppInfoTool.toolId)));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.infoModal), findsOneWidget);
    expect(find.text(const AppInfoTool().description), findsOneWidget);
  });
}
