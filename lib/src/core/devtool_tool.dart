import 'package:flutter/material.dart';

import 'devtool_controller.dart';

/// A tab on the devtool home screen that groups one or more tools.
///
/// Create one with a const variable and point your tools at it:
///
/// ```dart
/// const myStuffSection = DevtoolSection(id: 'my_stuff', title: 'My Stuff', icon: Icons.star_rounded);
/// ```
@immutable
class DevtoolSection {
  const DevtoolSection({required this.id, required this.title, required this.icon});

  final String id;
  final String title;
  final IconData icon;

  /// Tools the section ships with; registered tools are added to these.
  List<DevtoolTool> get tools => const [];

  /// Called once when the devtool is first built, before the tools.
  Future<void> init(DevtoolController controller) async {}

  /// Return a page to replace the default list of tool cards.
  Widget? buildPage(BuildContext context, DevtoolController controller) => null;

  void dispose() {}

  @override
  bool operator ==(Object other) => other is DevtoolSection && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A single card inside a [DevtoolSection]; extend this to add your own tool.
///
/// Declare the section it belongs to, then register it once before `runApp`:
///
/// ```dart
/// DevtoolTools.register(const MyCustomTool());
/// ```
abstract class DevtoolTool {
  const DevtoolTool();

  /// Tool id, for example "app_info".
  String get id;

  /// Card title, for example "App Information".
  String get title;

  /// Card icon, for example Icons.info_rounded.
  IconData get icon;

  /// Shown in the card's info modal.
  String get description;

  /// Section this tool shows up in; the section must be listed in
  /// [DevtoolConfig.sections] for the card to be reachable.
  DevtoolSection get section;

  /// Called once when the devtool is first built.
  Future<void> init(DevtoolController controller) async {}

  Widget build(BuildContext context, DevtoolController controller);

  void dispose() {}
}
