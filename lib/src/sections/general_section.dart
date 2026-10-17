import 'package:flutter/material.dart';

import '../core/devtool_tool.dart';
import '../tools/app_info/app_info_tool.dart';
import '../tools/network_usage/network_usage_tool.dart';

/// Default section; ships with [AppInfoTool] and [NetworkUsageTool].
class GeneralSection extends DevtoolSection {
  const GeneralSection({this.appInfo = const AppInfoTool(), this.networkUsage = const NetworkUsageTool()})
      : super(id: sectionId, title: 'General', icon: Icons.tune_rounded);

  static const sectionId = 'general';

  /// Pass a configured [AppInfoTool] to customise it, or null to hide it.
  final AppInfoTool? appInfo;

  /// Pass a configured [NetworkUsageTool] to customise it, or null to hide it.
  final NetworkUsageTool? networkUsage;

  @override
  List<DevtoolTool> get tools => [?appInfo, ?networkUsage];
}
