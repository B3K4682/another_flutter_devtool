import 'package:another_flutter_devtool/another_flutter_devtool.dart';
import 'package:flutter/material.dart';

/// Your own section; add it to `DevtoolConfig.sections` to show it on the home screen.
const playgroundSection = DevtoolSection(
  id: 'playground',
  title: 'Playground',
  icon: Icons.science_rounded,
);

/// Your own tool; it reaches [playgroundSection] through [section].
class MyCustomTool extends DevtoolTool {
  const MyCustomTool();

  @override
  String get id => 'my_custom_tool';

  @override
  String get title => 'My Custom Tool';

  @override
  IconData get icon => Icons.extension_rounded;

  @override
  String get description => 'A tool written by the app, registered with DevtoolTools.register.';

  @override
  DevtoolSection get section => playgroundSection;

  @override
  Widget build(BuildContext context, DevtoolController controller) {
    return DevtoolCard(
      key: DevtoolKeys.toolCard(id),
      icon: icon,
      title: title,
      description: description,
      infoButtonKey: DevtoolKeys.toolInfoButton(id),
      child: const DevtoolInfoRow(label: 'Status', value: 'It works'),
    );
  }
}


/// Another custom tool
class MyCustomTool2 extends DevtoolTool {
  const MyCustomTool2();

  @override
  String get id => 'my_custom_tool_2';

  @override
  String get title => 'My Custom Tool 2';

  @override
  IconData get icon => Icons.extension_rounded;

  @override
  String get description => 'A second tool written by the app, registered with DevtoolTools.register.';

  @override
  DevtoolSection get section => playgroundSection;

  @override
  Widget build(BuildContext context, DevtoolController controller) {
    return DevtoolCard(
      key: DevtoolKeys.toolCard(id),
      icon: icon,
      title: title,
      description: description,
      infoButtonKey: DevtoolKeys.toolInfoButton(id),
      child: const DevtoolInfoRow(label: 'Status', value: 'It works'),
    );
  }
}