import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const testScreenSize = Size(400, 800);

const testAppInfo = AppInfoData(
  appName: 'Example',
  version: '1.2.3',
  buildNumber: '42',
  deviceModel: 'Pixel 8',
  osVersion: 'Android 15 (SDK 35)',
  flavor: 'Debug',
  startupDuration: Duration(milliseconds: 412),
);

/// General section wired to fixed values instead of platform plugins.
const testGeneralSection = GeneralSection(appInfo: AppInfoTool(source: StaticAppInfoSource(testAppInfo)));

/// Section used to check that app-defined sections show up.
const testCustomSection = DevtoolSection(id: 'custom', title: 'Custom', icon: Icons.star_rounded);

/// Tool used to check that registered tools reach their section.
class TestCustomTool extends DevtoolTool {
  const TestCustomTool({this.section = testCustomSection, this.id = 'test_custom_tool'});

  @override
  final String id;

  @override
  final DevtoolSection section;

  @override
  String get title => 'Test Custom Tool';

  @override
  IconData get icon => Icons.extension_rounded;

  @override
  String get description => 'Tool registered by the app.';

  @override
  Widget build(BuildContext context, DevtoolController controller) => DevtoolCard(
        key: DevtoolKeys.toolCard(id),
        icon: icon,
        title: title,
        description: description,
        infoButtonKey: DevtoolKeys.toolInfoButton(id),
        child: const Text('custom tool body'),
      );
}

/// Counter app standing in for the host application under the devtool.
class TestHostApp extends StatefulWidget {
  const TestHostApp({super.key});

  @override
  State<TestHostApp> createState() => _TestHostAppState();
}

class _TestHostAppState extends State<TestHostApp> {
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

/// Pumps the devtool over [TestHostApp] at a fixed screen size.
Future<void> pumpDevtool(
  WidgetTester tester, {
  bool enabled = true,
  LauncherConfig launcher = const LauncherConfig(),
  List<DevtoolSection> sections = const [testGeneralSection],
  List<DevtoolTool> register = const [],
  DevtoolStorage? storage,
}) async {
  tester.view.physicalSize = testScreenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  DevtoolTools.clear();
  DevtoolTools.registerAll(register);
  addTearDown(DevtoolTools.clear);

  await tester.pumpWidget(
    AnotherFlutterDevtool(
      config: DevtoolConfig(
        enabled: enabled,
        launcher: launcher,
        sections: sections,
        storage: storage ?? InMemoryDevtoolStorage(),
      ),
      child: const TestHostApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the panel by tapping the launcher.
Future<void> openPanel(WidgetTester tester) async {
  await tester.tap(find.byKey(DevtoolKeys.launcher));
  await tester.pumpAndSettle();
}

/// Opens the section page for [sectionId] from the panel home grid.
Future<void> openSection(WidgetTester tester, String sectionId) async {
  await tester.tap(find.byKey(DevtoolKeys.sectionCard(sectionId)));
  await tester.pumpAndSettle();
}

/// Returns to the panel home if needed, then closes the panel.
Future<void> closePanel(WidgetTester tester) async {
  while (find.byKey(DevtoolKeys.closeButton).evaluate().isEmpty) {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(DevtoolKeys.closeButton));
  await tester.pumpAndSettle();
}
