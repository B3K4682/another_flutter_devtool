import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_info_data.dart';
import 'startup_tracker.dart';

/// Supplies the values shown by the App Information card.
abstract class AppInfoSource {
  const AppInfoSource();

  Future<AppInfoData> load({String? flavor});

  /// Latest startup measurement, read every time the card rebuilds.
  Duration? get startupDuration;
}

/// Reads real values from `package_info_plus` and `device_info_plus`.
class PlatformAppInfoSource extends AppInfoSource {
  const PlatformAppInfoSource();

  static const _unknown = 'Unknown';

  @override
  Duration? get startupDuration => DevtoolStartupTracker.instance.startupDuration;

  @override
  Future<AppInfoData> load({String? flavor}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final device = await _device();

    return AppInfoData(
      appName: packageInfo.appName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      deviceModel: device.$1,
      osVersion: device.$2,
      flavor: flavor ?? AppFlavor.current.label,
      startupDuration: startupDuration,
    );
  }

  Future<(String model, String osVersion)> _device() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        return (info.browserName.name, info.appVersion ?? _unknown);
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          return ('${info.manufacturer} ${info.model}', 'Android ${info.version.release} (SDK ${info.version.sdkInt})');
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          return (info.utsname.machine, '${info.systemName} ${info.systemVersion}');
        case TargetPlatform.windows:
          final info = await plugin.windowsInfo;
          return (info.productName, 'Windows ${info.displayVersion} (build ${info.buildNumber})');
        case TargetPlatform.macOS:
          final info = await plugin.macOsInfo;
          return (info.model, 'macOS ${info.osRelease}');
        case TargetPlatform.linux:
          final info = await plugin.linuxInfo;
          return (info.prettyName, info.version ?? _unknown);
        case TargetPlatform.fuchsia:
          return (_unknown, _unknown);
      }
    } catch (_) {
      return (_unknown, _unknown);
    }
  }
}

/// Source with fixed values; useful for tests and for overriding fields.
class StaticAppInfoSource extends AppInfoSource {
  const StaticAppInfoSource(this.data);

  final AppInfoData data;

  @override
  Duration? get startupDuration => data.startupDuration;

  @override
  Future<AppInfoData> load({String? flavor}) async =>
      flavor == null ? data : AppInfoData(
            appName: data.appName,
            version: data.version,
            buildNumber: data.buildNumber,
            deviceModel: data.deviceModel,
            osVersion: data.osVersion,
            flavor: flavor,
            startupDuration: data.startupDuration,
          );
}
