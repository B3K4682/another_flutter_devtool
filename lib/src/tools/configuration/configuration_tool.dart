import 'package:flutter/material.dart';

import '../../core/devtool_controller.dart';
import '../../core/devtool_tool.dart';
import '../../sections/general_section.dart';
import 'configuration_card.dart';

/// App-level controls; currently lets you jump straight to a route.
class ConfigurationTool extends DevtoolTool {
  const ConfigurationTool({this.onNavigate});

  static const toolId = 'configuration';

  /// Called with the typed route, for example "/example", after the devtool
  /// closes. Wire it to your router; navigation is disabled while null.
  final void Function(String route)? onNavigate;

  @override
  String get id => toolId;

  @override
  String get title => 'Configuration';

  @override
  IconData get icon => Icons.settings_rounded;

  @override
  String get description =>
      'Controls for the running app.\n'
      '• Navigation: Type a route like /example and press Go to close the devtool and open it\n';

  @override
  DevtoolSection get section => const GeneralSection();

  @override
  Widget build(BuildContext context, DevtoolController controller) =>
      ConfigurationCard(tool: this, controller: controller);
}
