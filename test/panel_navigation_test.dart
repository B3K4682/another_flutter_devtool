import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

void main() {
  final generalCard = find.byKey(DevtoolKeys.sectionCard(GeneralSection.sectionId));
  final generalPage = find.byKey(DevtoolKeys.sectionPage(GeneralSection.sectionId));
  final customCard = find.byKey(DevtoolKeys.sectionCard(testCustomSection.id));
  final appInfoCard = find.byKey(DevtoolKeys.toolCard(AppInfoTool.toolId));
  final customToolCard = find.byKey(DevtoolKeys.toolCard('test_custom_tool'));

  testWidgets('without sections the grid is empty', (tester) async {
    await pumpDevtool(tester, sections: const []);
    await openPanel(tester);

    expect(generalCard, findsNothing);
    expect(find.textContaining('No sections configured'), findsOneWidget);
  });

  testWidgets('the General section is configured by default', (tester) async {
    await pumpDevtool(tester);
    await openPanel(tester);

    expect(generalCard, findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(appInfoCard, findsNothing);
  });

  testWidgets('tapping General opens the section page with its tool cards', (tester) async {
    await pumpDevtool(tester);
    await openPanel(tester);
    await openSection(tester, GeneralSection.sectionId);

    expect(generalPage, findsOneWidget);
    expect(appInfoCard, findsOneWidget);
    expect(find.text('App Information'), findsOneWidget);
  });

  testWidgets('an app section becomes a card and hosts its registered tool', (tester) async {
    await pumpDevtool(
      tester,
      sections: const [testGeneralSection, testCustomSection],
      register: const [TestCustomTool()],
    );
    await openPanel(tester);

    expect(generalCard, findsOneWidget);
    expect(customCard, findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    await openSection(tester, testCustomSection.id);

    expect(customToolCard, findsOneWidget);
    expect(find.text('custom tool body'), findsOneWidget);
    expect(appInfoCard, findsNothing);
  });

  testWidgets('a registered tool lands in the General section too', (tester) async {
    await pumpDevtool(tester, register: const [TestCustomTool(section: GeneralSection())]);
    await openPanel(tester);
    await openSection(tester, GeneralSection.sectionId);

    expect(appInfoCard, findsOneWidget);
    await tester.scrollUntilVisible(
      customToolCard,
      100,
      scrollable: find.descendant(of: generalPage, matching: find.byType(Scrollable)).first,
    );
    expect(customToolCard, findsOneWidget);
  });

  testWidgets('a tool whose section is not configured stays hidden', (tester) async {
    await pumpDevtool(tester, register: const [TestCustomTool()]);
    await openPanel(tester);

    expect(customCard, findsNothing);
    expect(generalCard, findsOneWidget);
  });

  testWidgets('back from a section returns to the grid without closing the panel', (tester) async {
    await pumpDevtool(tester);
    await openPanel(tester);
    await openSection(tester, GeneralSection.sectionId);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(generalPage, findsNothing);
    expect(generalCard, findsOneWidget);
    expect(find.byKey(DevtoolKeys.panel), findsOneWidget);
  });

  testWidgets('back from the grid closes the panel', (tester) async {
    await pumpDevtool(tester);
    await openPanel(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.panel), findsNothing);
    expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);
  });

  testWidgets('the close button closes the panel from the grid', (tester) async {
    await pumpDevtool(tester);
    await openPanel(tester);

    await tester.tap(find.byKey(DevtoolKeys.closeButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.panel), findsNothing);
    expect(find.byKey(DevtoolKeys.launcher), findsOneWidget);
  });

  testWidgets('section cards are laid out two per row', (tester) async {
    await pumpDevtool(tester);
    await openPanel(tester);

    final cardWidth = tester.getSize(generalCard).width;
    final expected = (testScreenSize.width - 2 * DevtoolSpacing.padding - DevtoolSpacing.gap) / 2;
    expect(cardWidth, expected);
  });
}
