import 'package:flutter/widgets.dart';

/// Measures the time from app start to the first rasterized frame.
class DevtoolStartupTracker {
  DevtoolStartupTracker._();

  static final instance = DevtoolStartupTracker._();

  Stopwatch? _stopwatch;
  Duration? _startupDuration;

  /// Time to the first frame, or null while it is still being measured.
  Duration? get startupDuration => _startupDuration;

  /// Starts the measurement; safe to call more than once.
  void markStart() {
    _stopwatch ??= Stopwatch()..start();
  }

  /// Stops the measurement once the first frame has been rasterized.
  void trackFirstFrame() {
    if (_startupDuration != null) return;
    markStart();
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
      final stopwatch = _stopwatch;
      if (stopwatch == null || _startupDuration != null) return;
      stopwatch.stop();
      _startupDuration = stopwatch.elapsed;
    });
  }

  @visibleForTesting
  void resetForTest({Duration? startupDuration}) {
    _stopwatch = null;
    _startupDuration = startupDuration;
  }
}
