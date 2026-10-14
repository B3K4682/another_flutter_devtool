import 'package:flutter/material.dart';

import '../../core/devtool_controller.dart';
import '../../core/devtool_tool.dart';
import '../../sections/general_section.dart';
import 'app_info_card.dart';
import 'app_info_source.dart';
import 'app_info_state.dart';

/// Shows app version, device, OS, flavor and startup time in the General tab.
class AppInfoTool extends DevtoolTool {
  const AppInfoTool({
    this.source = const PlatformAppInfoSource(),
    this.flavor,
    this.showVersionBadgeByDefault = true,
  });

  static const toolId = 'app_info';

  /// Override to supply your own values, for example in tests.
  final AppInfoSource source;

  /// Custom flavor name; defaults to Debug, Profile or Release.
  final String? flavor;

  /// Initial value of the version badge toggle when nothing is stored yet.
  final bool showVersionBadgeByDefault;

  @override
  String get id => toolId;

  @override
  String get title => 'App Information';

  @override
  IconData get icon => Icons.phone_iphone_rounded;

  @override
  String get description =>
      'Displays current app build and device information.\n'
      '• App Version: Current version and build number\n'
      '• Device: Model and OS version\n'
      '• Flavor: Active flavor (Debug, Profile, Release)\n'
      '• Startup Time: How long the app took to render its first frame\n';

  @override
  DevtoolSection get section => const GeneralSection();

  @override
  Future<void> init(DevtoolController controller) async {
    controller.registerBoolSetting(
      DevtoolController.showVersionBadgeKey,
      defaultValue: showVersionBadgeByDefault,
    );

    final state = AppInfoState(source: source, flavor: flavor)..addListener(controller.refresh);
    controller.registerToolState(toolId, state);
    await state.load();
  }

  @override
  Widget build(BuildContext context, DevtoolController controller) =>
      AppInfoCard(tool: this, controller: controller);
}
