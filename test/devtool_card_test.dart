import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, {String? description}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: DevtoolTheme.dark(),
        home: Scaffold(
          body: DevtoolCard(
            icon: Icons.info_rounded,
            title: 'App Information',
            description: description,
            infoButtonKey: DevtoolKeys.toolInfoButton('app_info'),
            child: const Text('card body'),
          ),
        ),
      ),
    );
  }

  final infoButton = find.byKey(DevtoolKeys.toolInfoButton('app_info'));

  testWidgets('renders the title, icon and body', (tester) async {
    await pumpCard(tester);

    expect(find.text('App Information'), findsOneWidget);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    expect(find.text('card body'), findsOneWidget);
  });

  testWidgets('the info button only appears with a description', (tester) async {
    await pumpCard(tester);
    expect(infoButton, findsNothing);

    await pumpCard(tester, description: 'What this card does.');
    expect(infoButton, findsOneWidget);
  });

  testWidgets('tapping the info button opens and dismisses the modal', (tester) async {
    await pumpCard(tester, description: 'What this card does.');

    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.infoModal), findsOneWidget);
    expect(find.text('What this card does.'), findsOneWidget);
    expect(find.text('App Information'), findsNWidgets(2));

    await tester.tap(find.byKey(DevtoolKeys.infoModalCloseButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DevtoolKeys.infoModal), findsNothing);
  });

  testWidgets('info rows show label, value and semantic color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DevtoolTheme.dark(),
        home: const Scaffold(
          body: DevtoolInfoRow(label: 'Current flavor', value: 'Debug', valueColor: DevtoolColors.warning),
        ),
      ),
    );

    expect(find.text('Current flavor'), findsOneWidget);
    final value = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(value.data, 'Debug');
    expect(value.style?.color, DevtoolColors.warning);
  });
}
