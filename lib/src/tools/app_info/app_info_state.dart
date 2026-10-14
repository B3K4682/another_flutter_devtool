import 'package:flutter/foundation.dart';

import 'app_info_data.dart';
import 'app_info_source.dart';

/// Holds the loaded [AppInfoData] for the App Information card and the badge.
class AppInfoState extends ChangeNotifier {
  AppInfoState({required this.source, this.flavor});

  final AppInfoSource source;
  final String? flavor;

  AppInfoData? _data;

  AppInfoData? get data => _data;

  Future<void> load() async {
    final loaded = await source.load(flavor: flavor);
    _data = loaded;
    notifyListeners();
  }

  /// Re-reads the startup measurement, which lands after the first frame.
  void refreshStartup() {
    final data = _data;
    final duration = source.startupDuration;
    if (data == null || duration == null || data.startupDuration == duration) return;
    _data = data.copyWith(startupDuration: duration);
    notifyListeners();
  }
}
