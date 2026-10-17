import 'package:flutter/material.dart';

import '../../core/devtool_controller.dart';
import '../../core/devtool_tool.dart';
import '../../sections/general_section.dart';
import 'network_usage_card.dart';
import 'network_usage_tracker.dart';

/// Shows HTTP data received, sent, request count and top hosts since launch.
///
/// Works with Dio, the http package and anything else built on dart:io's
/// HttpClient. Not available on web.
class NetworkUsageTool extends DevtoolTool {
  const NetworkUsageTool({this._tracker, this.topHostCount = 5});

  static const toolId = 'network_usage';

  final NetworkUsageTracker? _tracker;

  /// How many hosts the "Top hosts" list shows.
  final int topHostCount;

  /// Defaults to [NetworkUsageTracker.instance].
  NetworkUsageTracker get tracker => _tracker ?? NetworkUsageTracker.instance;

  @override
  String get id => toolId;

  @override
  String get title => 'Internet Data Usage';

  @override
  IconData get icon => Icons.swap_vert_rounded;

  @override
  String get description =>
      'Counts HTTP traffic since launch (Dio, http and other dart:io clients).\n'
      '• Received: Data downloaded, including response headers\n'
      '• Sent: Data uploaded, including request headers\n'
      '• Total: Received and sent combined\n'
      '• Requests: Number of HTTP requests made\n'
      '• Top hosts: Hosts that received the most data\n';

  @override
  DevtoolSection get section => const GeneralSection();

  @override
  Future<void> init(DevtoolController controller) async => tracker.install();

  @override
  Widget build(BuildContext context, DevtoolController controller) => NetworkUsageCard(tool: this);
}
