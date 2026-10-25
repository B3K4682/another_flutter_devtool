import 'package:flutter/foundation.dart';

/// Build flavor the app is currently running in.
enum AppFlavor {
  debug('Debug'),
  profile('Profile'),
  release('Release');

  const AppFlavor(this.label);

  final String label;

  /// Flavor of the running binary.
  static AppFlavor get current {
    if (kDebugMode) return AppFlavor.debug;
    if (kProfileMode) return AppFlavor.profile;
    return AppFlavor.release;
  }
}

/// Snapshot of app, device and startup information.
@immutable
class AppInfoData {
  const AppInfoData({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.deviceModel,
    required this.osVersion,
    required this.flavor,
    this.startupDuration,
  });

  final String appName;
  final String version;
  final String buildNumber;
  final String deviceModel;
  final String osVersion;

  /// Custom flavor name when provided, otherwise [AppFlavor.label].
  final String flavor;

  /// Time from app start to the first rasterized frame.
  final Duration? startupDuration;

  /// Version and build number as shown in the UI, for example `1.2.0 (42)`.
  String get versionLabel => buildNumber.isEmpty ? version : '$version ($buildNumber)';

  /// Compact version for the launcher badge.
  String get badgeLabel => 'v$versionLabel';

  String get startupLabel {
    final duration = startupDuration;
    if (duration == null) return 'Measuring...';
    if (duration.inMilliseconds < 1000) return '${duration.inMilliseconds} ms';
    return '${(duration.inMicroseconds / 1000000).toStringAsFixed(2)} s';
  }

  AppInfoData copyWith({Duration? startupDuration}) => AppInfoData(
    appName: appName,
    version: version,
    buildNumber: buildNumber,
    deviceModel: deviceModel,
    osVersion: osVersion,
    flavor: flavor,
    startupDuration: startupDuration ?? this.startupDuration,
  );
}
