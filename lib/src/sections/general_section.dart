import 'package:flutter/material.dart';

import '../core/devtool_tool.dart';
import '../tools/app_info/app_info_tool.dart';

/// Default section; ships with [AppInfoTool] and hosts the built-in tools.
class GeneralSection extends DevtoolSection {
  const GeneralSection({this.appInfo = const AppInfoTool()})
      : super(id: sectionId, title: 'General', icon: Icons.tune_rounded);

  static const sectionId = 'general';

  /// Pass a configured [AppInfoTool] to customise it, or null to hide it.
  final AppInfoTool? appInfo;

  @override
  List<DevtoolTool> get tools => [?appInfo];
}
