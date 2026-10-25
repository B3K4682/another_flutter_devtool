import '../core/devtool_storage.dart';
import '../core/devtool_tool.dart';
import '../sections/general_section.dart';

/// Top-level configuration for [AnotherFlutterDevtool].
class DevtoolConfig {
  const DevtoolConfig({
    this.enabled = false,
    this.launcher = const LauncherConfig(),
    this.sections = const [GeneralSection()],
    this.storage,
  });

  /// When false, the devtool renders only the wrapped child.
  final bool enabled;

  /// Configuration for the floating launcher button.
  final LauncherConfig launcher;

  /// Sections shown as cards on the devtool home screen. Tools find their
  /// section on their own through [DevtoolTool.section].
  final List<DevtoolSection> sections;

  /// Overrides the default `shared_preferences` storage; useful in tests.
  final DevtoolStorage? storage;
}

/// Configuration for the floating, draggable launcher button.
class LauncherConfig {
  const LauncherConfig({this.enabled = true, this.initiallyVisible = true});

  /// When false, the launcher is never shown.
  final bool enabled;

  /// Whether the launcher is visible when the app starts.
  final bool initiallyVisible;

  // TODO: Might as well add props for launcher size, color, etc.
}
