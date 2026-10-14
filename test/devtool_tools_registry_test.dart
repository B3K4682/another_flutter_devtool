import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/devtool_test_harness.dart';

void main() {
  DevtoolController controllerWith(List<DevtoolSection> sections) => DevtoolController(
        config: DevtoolConfig(enabled: true, sections: sections),
        storage: InMemoryDevtoolStorage(),
      );

  tearDown(DevtoolTools.clear);

  test('sections keep their configured order', () {
    final controller = controllerWith(const [testCustomSection, GeneralSection()]);

    expect(controller.sections.map((section) => section.id), ['custom', 'general']);
  });

  test('General ships with the app info tool and nothing else', () {
    final controller = controllerWith(const [GeneralSection()]);

    expect(controller.toolsOf(const GeneralSection()).map((tool) => tool.id), [AppInfoTool.toolId]);
  });

  test('General can be configured without the app info tool', () {
    final controller = controllerWith(const [GeneralSection(appInfo: null)]);

    expect(controller.toolsOf(const GeneralSection()), isEmpty);
    expect(controller.tools, isEmpty);
  });

  test('a registered tool joins the section it belongs to', () {
    DevtoolTools.register(const TestCustomTool());
    final controller = controllerWith(const [GeneralSection(), testCustomSection]);

    expect(controller.toolsOf(testCustomSection).map((tool) => tool.id), ['test_custom_tool']);
    expect(controller.tools.map((tool) => tool.id), [AppInfoTool.toolId, 'test_custom_tool']);
  });

  test('a registered tool replaces a built-in with the same id', () {
    DevtoolTools.register(const AppInfoTool(flavor: 'Staging'));
    final controller = controllerWith(const [GeneralSection()]);

    final tools = controller.toolsOf(const GeneralSection());
    expect(tools, hasLength(1));
    expect((tools.single as AppInfoTool).flavor, 'Staging');
  });

  test('registering the same id twice keeps the last tool', () {
    DevtoolTools.register(const TestCustomTool());
    DevtoolTools.register(const TestCustomTool(section: GeneralSection()));

    expect(DevtoolTools.registered, hasLength(1));
    expect(DevtoolTools.registered.single.section, const GeneralSection());
  });

  test('tools can be unregistered and cleared', () {
    DevtoolTools.registerAll(const [TestCustomTool(), TestCustomTool(id: 'other')]);
    expect(DevtoolTools.registered, hasLength(2));

    DevtoolTools.unregister('other');
    expect(DevtoolTools.registered.map((tool) => tool.id), ['test_custom_tool']);

    DevtoolTools.clear();
    expect(DevtoolTools.registered, isEmpty);
  });

  test('tools pointing at unconfigured sections are left out', () {
    DevtoolTools.register(const TestCustomTool());
    final controller = controllerWith(const [GeneralSection()]);

    expect(controller.tools.map((tool) => tool.id), [AppInfoTool.toolId]);
  });

  test('sections compare by id', () {
    expect(const GeneralSection(), const GeneralSection(appInfo: null));
    expect(const GeneralSection(), isNot(testCustomSection));
  });
}
