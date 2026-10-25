import 'package:flutter/material.dart';

import '../theme/devtool_theme.dart';
import 'network_call.dart';

/// `223 ms`, `1.24 s` or `1m 3s`.
String formatDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms < 1000) return '$ms ms';
  if (ms < 60000) return '${(ms / 1000).toStringAsFixed(2)} s';
  return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
}

/// `20:11:05.123`.
String formatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.${time.millisecond.toString().padLeft(3, '0')}';
}

Color statusColor(NetworkStatusGroup group) => switch (group) {
  NetworkStatusGroup.success => DevtoolColors.success,
  NetworkStatusGroup.informational || NetworkStatusGroup.redirect => DevtoolColors.info,
  NetworkStatusGroup.clientError => DevtoolColors.warning,
  NetworkStatusGroup.serverError || NetworkStatusGroup.failed => DevtoolColors.error,
  NetworkStatusGroup.pending => DevtoolColors.textSecondary,
};

/// Host, port and path with query, without the scheme.
String displayUrl(Uri uri) {
  final text = uri.toString();
  final scheme = text.indexOf('://');
  return scheme == -1 ? text : text.substring(scheme + 3);
}

/// Monospace text style for URLs, headers and bodies.
const monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Menlo', 'Consolas', 'Roboto Mono'],
  fontSize: 12,
  height: 1.45,
  color: DevtoolColors.textPrimary,
);
