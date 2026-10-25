import 'package:flutter/widgets.dart';

/// Keys for locating devtool widgets in tests.
abstract final class DevtoolKeys {
  static const launcher = ValueKey('another_flutter_devtool.launcher');
  static const versionBadge = ValueKey('another_flutter_devtool.version_badge');
  static const panel = ValueKey('another_flutter_devtool.panel');
  static const closeButton = ValueKey('another_flutter_devtool.close_button');
  static const infoModal = ValueKey('another_flutter_devtool.info_modal');
  static const infoModalCloseButton = ValueKey('another_flutter_devtool.info_modal_close_button');
  static const networkUsageResetButton = ValueKey('another_flutter_devtool.network_usage_reset_button');
  static const configurationRouteField = ValueKey('another_flutter_devtool.configuration_route_field');
  static const configurationGoButton = ValueKey('another_flutter_devtool.configuration_go_button');

  static const networkCallsPage = ValueKey('another_flutter_devtool.network_calls_page');
  static const networkSearchField = ValueKey('another_flutter_devtool.network_search_field');
  static const networkPauseButton = ValueKey('another_flutter_devtool.network_pause_button');
  static const networkExportButton = ValueKey('another_flutter_devtool.network_export_button');
  static const networkClearButton = ValueKey('another_flutter_devtool.network_clear_button');
  static const networkCallCount = ValueKey('another_flutter_devtool.network_call_count');
  static const networkCallDetails = ValueKey('another_flutter_devtool.network_call_details');
  static const networkCopyCurlButton = ValueKey('another_flutter_devtool.network_copy_curl_button');
  static const networkExportCallButton = ValueKey('another_flutter_devtool.network_export_call_button');

  /// [filter] is one of `all`, `2xx`, `3xx`, `4xx`, `5xx` or `failed`.
  static ValueKey<String> networkStatusFilter(String filter) =>
      ValueKey('another_flutter_devtool.network_status_filter.$filter');

  static ValueKey<String> networkCallRow(int callId) => ValueKey('another_flutter_devtool.network_call_row.$callId');

  static ValueKey<String> sectionCard(String sectionId) => ValueKey('another_flutter_devtool.section_card.$sectionId');

  static ValueKey<String> sectionPage(String sectionId) => ValueKey('another_flutter_devtool.section_page.$sectionId');

  static ValueKey<String> toolCard(String toolId) => ValueKey('another_flutter_devtool.tool_card.$toolId');

  static ValueKey<String> toolInfoButton(String toolId) => ValueKey('another_flutter_devtool.tool_info_button.$toolId');
}
