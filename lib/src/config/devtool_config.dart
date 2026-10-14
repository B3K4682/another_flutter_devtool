/// Top-level configuration for [AnotherFlutterDevtool].
class DevtoolConfig {
  const DevtoolConfig({
    this.enabled = false,
    this.launcher = const LauncherConfig(),
  });

  /// When false, the devtool renders only the wrapped child.
  final bool enabled;

  /// Configuration for the floating launcher button.
  final LauncherConfig launcher;
}

/// Configuration for the floating, draggable launcher button.
class LauncherConfig {
  const LauncherConfig({
    this.enabled = true,
    this.initiallyVisible = true,
  });

  /// When false, the launcher is never shown.
  final bool enabled;

  /// Whether the launcher is visible when the app starts.
  final bool initiallyVisible;

  // TODO: Might as well add props for launcher size, color, etc.
}
