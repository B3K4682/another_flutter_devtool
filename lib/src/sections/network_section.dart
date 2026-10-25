import 'package:flutter/material.dart';

import '../core/devtool_controller.dart';
import '../core/devtool_tool.dart';
import '../network/network_calls_page.dart';
import '../network/network_export.dart';
import '../network/network_recorder.dart';

/// Records every HTTP call (Dio, http and other dart:io clients) and lists them.
/// Not available on web.
class NetworkSection extends DevtoolSection {
  const NetworkSection({this._recorder, this.redactedHeaders = defaultRedactedHeaders})
    : super(id: sectionId, title: 'Network', icon: Icons.lan_outlined);

  static const sectionId = 'network';

  final NetworkRecorder? _recorder;

  /// Header names (lowercase) masked in JSON exports.
  final Set<String> redactedHeaders;

  /// Defaults to [NetworkRecorder.instance].
  NetworkRecorder get recorder => _recorder ?? NetworkRecorder.instance;

  @override
  Future<void> init(DevtoolController controller) async => recorder.install();

  @override
  Widget buildPage(BuildContext context, DevtoolController controller) =>
      NetworkCallsPage(recorder: recorder, redactedHeaders: redactedHeaders);
}
